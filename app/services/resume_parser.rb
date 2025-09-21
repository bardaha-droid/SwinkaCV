require 'zip'
require 'pdf/reader'
require 'nokogiri'

class ResumeParser
  class UnsupportedFile < StandardError; end

  SUPPORTED_MIME_TYPES = {
    'application/pdf' => :pdf,
    'application/msword' => :doc,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => :docx,
    'text/plain' => :text
  }.freeze

  def initialize(uploaded_file)
    @uploaded_file = uploaded_file
  end

  def extract_text
    case detected_type
    when :pdf
      extract_pdf
    when :docx
      extract_docx
    when :text
      extract_plain_text
    else
      raise UnsupportedFile, 'Only PDF, DOCX, and plain text resumes are supported right now.'
    end
  end

  private

  attr_reader :uploaded_file

  def detected_type
    mime_type = uploaded_file.content_type.presence
    extension = File.extname(uploaded_file.original_filename).delete('.').downcase

    return SUPPORTED_MIME_TYPES[mime_type] if mime_type && SUPPORTED_MIME_TYPES.key?(mime_type)

    case extension
    when 'pdf' then :pdf
    when 'docx' then :docx
    when 'txt' then :text
    else
      nil
    end
  end

  def extract_pdf
    uploaded_file.tempfile.rewind
    reader = PDF::Reader.new(uploaded_file.tempfile)
    reader.pages.map(&:text).join("\n\n")
  rescue PDF::Reader::MalformedPDFError => e
    Rails.logger.warn("PDF parsing error: #{e.message}")
    raise UnsupportedFile, 'We could not read that PDF file.'
  end

  def extract_docx
    uploaded_file.tempfile.rewind
    text = []
    Zip::File.open(uploaded_file.tempfile.path) do |zip_file|
      document_xml = zip_file.read('word/document.xml')
      doc = Nokogiri::XML(document_xml)
      doc.remove_namespaces!
      doc.xpath('//p').each do |paragraph|
        line = paragraph.xpath('.//t').map(&:text).join
        text << line.strip
      end
    end
    text.reject(&:blank?).join("\n")
  rescue Zip::Error
    raise UnsupportedFile, 'We could not read that DOCX file.'
  end

  def extract_plain_text
    uploaded_file.tempfile.rewind
    uploaded_file.tempfile.read
  end
end
