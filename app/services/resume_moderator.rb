class ResumeModerator
  class Rejected < StandardError; end

  MIN_CHAR_COUNT = 300
  MAX_CHAR_COUNT = 60_000

  KEYWORDS = %w[
    experience experiences education edukacja wykształcenie skills umiejętności summary profil projects projekty
    employment zatrudnienie responsibilities obowiązki achievements osiągnięcia
  ].freeze

  BANNED_PATTERNS = [
    /<script/i,
    /drop\s+table/i,
    /insert\s+into/i,
    /--\s*select/i
  ].freeze

  def self.validate!(text)
    new(text).validate!
  end

  def initialize(text)
    @text = text.to_s.strip
  end

  def validate!
    raise Rejected, 'Prześlij CV z konkretną treścią – obecny plik wydaje się pusty.' if text.blank?
    raise Rejected, 'CV jest bardzo krótkie. Dodaj kilka zdań o doświadczeniu i umiejętnościach.' if text.length < MIN_CHAR_COUNT
    raise Rejected, 'CV jest bardzo długie (ponad 60 000 znaków). Skróć dokument zanim prześlesz ponownie.' if text.length > MAX_CHAR_COUNT
    raise Rejected, 'W treści wykryto podejrzane fragmenty (np. kod). Usuń je przed przesłaniem.' if banned_content?
    raise Rejected, 'Nie wygląda to na CV. Dodaj sekcje z doświadczeniem, edukacją lub umiejętnościami.' unless contains_keywords?

    true
  end

  private

  attr_reader :text

  def banned_content?
    BANNED_PATTERNS.any? { |pattern| text.match?(pattern) }
  end

  def contains_keywords?
    lowercase = text.downcase
    KEYWORDS.count { |keyword| lowercase.include?(keyword) } >= 2
  end
end
