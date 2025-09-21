require 'openai'

class CoverLetterGenerator
  class GenerationError < StandardError; end

  DEFAULT_MODEL = 'gpt-4.1'.freeze

  def initialize(resume_text:, job_description: nil)
    @resume_text = resume_text.to_s.strip
    @job_description = job_description.to_s.strip.presence
    @model = ENV.fetch('OPENAI_MODEL', DEFAULT_MODEL)
  end

  def call
    raise GenerationError, 'Resume text is required.' if resume_text.blank?
    raise GenerationError, 'OpenAI API key is missing.' unless ENV['OPENAI_API_KEY'].present?

    cover_letter = generate_with_openai
    raise GenerationError, 'Cover letter generation failed.' if cover_letter.blank?

    cover_letter.strip
  end

  private

  attr_reader :resume_text, :job_description, :model

  def generate_with_openai
    client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
    response = client.chat(parameters: build_parameters)
    response.dig('choices', 0, 'message', 'content')
  end

  def build_parameters
    user_prompt = <<~PROMPT
      Resume:
      #{resume_text}
    PROMPT
    if job_description
      user_prompt << "\nTarget role description:\n#{job_description}\n"
    end

    {
      model: model,
      messages: [
        {
          role: 'system',
          content: 'You are a professional cover letter writer. Craft complete, polished cover letters based strictly on the provided resume. Write about half to a full page (~320-420 words) in a confident, personable tone. Use clear paragraphs and avoid lists or bullet points.'
        },
        { role: 'user', content: user_prompt.strip }
      ],
      temperature: 0.65
    }
  end
end
