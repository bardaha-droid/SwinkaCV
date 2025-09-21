module Api
  class ResumesController < BaseController
    def create
      uploaded_file = params[:file]

      unless uploaded_file.present?
        render json: { error: 'Please attach a resume file.' }, status: :bad_request
        return
      end

      parser = ResumeParser.new(uploaded_file)
      resume_text = parser.extract_text
      ResumeModerator.validate!(resume_text)

      render json: { resume_text: resume_text }
    rescue ResumeParser::UnsupportedFile => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue ResumeModerator::Rejected => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error("Resume parsing failed: #{e.message}")
      render json: { error: 'Nie udało się odczytać CV. Spróbuj ponownie za chwilę lub użyj innego pliku.' }, status: :internal_server_error
    end
  end
end
