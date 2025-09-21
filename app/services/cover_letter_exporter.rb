require 'caracal'
require 'prawn'

class CoverLetterExporter
  class UnsupportedFormat < StandardError; end

  def self.to_docx(content)
    document = Caracal::Document.new do |doc|
      doc.page_margins do
        top 720
        bottom 720
        left 720
        right 720
      end

      paragraphs_for(content).each do |paragraph|
        doc.p paragraph
      end
    end

    document.render
  end

  def self.to_pdf(content)
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 54)
    if (font_path = unicode_font_path)
      pdf.font font_path
    else
      Rails.logger.warn('Unicode-capable font not found; falling back to Helvetica. Some characters may not render correctly.')
    end

    paragraphs_for(content).each do |paragraph|
      pdf.text(paragraph, leading: 4)
      pdf.move_down 12
    end
    pdf.render
  end

  def self.paragraphs_for(content)
    content.to_s.split(/\n{2,}/).map(&:strip).reject(&:blank?).presence || [content.to_s.strip]
  end
  private_class_method :paragraphs_for

  def self.unicode_font_path
    @unicode_font_path ||= begin
      candidate_files = [
        Rails.root.join('app/assets/fonts/SwinkaCV-Regular.ttf'),
        Rails.root.join('app/assets/fonts/NotoSans-Regular.ttf'),
        Rails.root.join('vendor/assets/fonts/SwinkaCV-Regular.ttf'),
        '/Library/Fonts/Arial Unicode.ttf',
        '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        '/Library/Fonts/NotoSans-Regular.ttf'
      ]

      match = candidate_files.find { |path| File.exist?(path) }
      match&.to_s
    end
  end
  private_class_method :unicode_font_path
end
