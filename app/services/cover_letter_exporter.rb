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
end
