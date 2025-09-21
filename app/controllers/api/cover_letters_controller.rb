module Api
  class CoverLettersController < BaseController
    def create
      resume_text = params[:resume_text].to_s
      job_description = params[:job_description].to_s.presence

      if resume_text.blank?
        render json: { error: 'Resume text is required to generate a cover letter.' }, status: :bad_request
        return
      end

      generator = CoverLetterGenerator.new(resume_text: resume_text, job_description: job_description)
      cover_letter = generator.call

      render json: { cover_letter: cover_letter }
    rescue CoverLetterGenerator::GenerationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error("Cover letter generation failed: #{e.message}")
      render json: { error: 'Nie udało się wygenerować listu motywacyjnego. Spróbuj ponownie za chwilę.' }, status: :internal_server_error
    end

    def export
      cover_letter = params[:cover_letter].to_s
      format = params[:format].to_s.downcase

      if cover_letter.blank?
        render json: { error: 'Cover letter content is missing.' }, status: :bad_request
        return
      end

      data, filename, mime_type = case format
      when 'docx'
        [CoverLetterExporter.to_docx(cover_letter), 'cover_letter.docx',
         'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
      when 'pdf'
        [CoverLetterExporter.to_pdf(cover_letter), 'cover_letter.pdf', 'application/pdf']
      else
        render json: { error: 'Unsupported export format.' }, status: :unprocessable_entity
        return
      end

      send_data data, filename: filename, type: mime_type, disposition: 'attachment'
    rescue StandardError => e
      Rails.logger.error("Cover letter export failed: #{e.message}")
      render json: { error: 'We could not create the requested download.' }, status: :internal_server_error
    end
  end
end
