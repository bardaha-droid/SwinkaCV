class ContactExtractor
  NAME_REGEX = /\A([A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+)(?:[\s\-]+([A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+))+/
  EMAIL_REGEX = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i
  PHONE_REGEX = /\+?\d[\d\s\-()]{6,}\d/
  ADDRESS_KEYWORDS = %w[ul. ulica street st. ave avenue al. aleja aleje apt mieszkanie lok lok. apartment]

  def initialize(resume_text)
    @resume_text = resume_text.to_s
    @lines = @resume_text.split(/\r?\n+/).map(&:strip).reject(&:blank?)
  end

  def extract
    {
      first_name: first_name,
      last_name: last_name,
      address: address,
      phone: phone,
      email: email
    }.compact_blank
  end

  private

  attr_reader :resume_text, :lines

  def email
    resume_text[EMAIL_REGEX]
  end

  def phone
    match = resume_text.match(PHONE_REGEX)
    return unless match

    normalized = match[0].gsub(/[\s()-]+/, ' ').squeeze(' ').strip
    normalized
  end

  def first_name
    name_components[:first_name]
  end

  def last_name
    name_components[:last_name]
  end

  def name_components
    @name_components ||= begin
      candidates = lines.first(5)
      candidates.each do |line|
        next if line.length > 80

        stripped = line.gsub(/[,;]|\d/, '').strip
        next if stripped.blank?

        if (match = stripped.match(NAME_REGEX))
          parts = stripped.split(/[\s\-]+/)
          next if parts.size < 2

          return { first_name: parts.first, last_name: parts.last }
        end
      end
      {}
    end
  end

  def address
    lines.each do |line|
      normalized = line.downcase
      if ADDRESS_KEYWORDS.any? { |keyword| normalized.include?(keyword) }
        return line
      end
    end

    nil
  end
end
