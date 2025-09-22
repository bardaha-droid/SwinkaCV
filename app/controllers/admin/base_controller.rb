module Admin
  class BaseController < ApplicationController
    layout 'application'

    before_action :authenticate

    private

    def authenticate
      username = ENV.fetch('ADMIN_USERNAME', nil)
      password = ENV.fetch('ADMIN_PASSWORD', nil)

      unless username.present? && password.present?
        render plain: 'Admin credentials are not configured.', status: :forbidden
        return
      end

      authenticate_or_request_with_http_basic('Swinka.CV Admin') do |provided_username, provided_password|
        ActiveSupport::SecurityUtils.secure_compare(provided_username, username) &&
          ActiveSupport::SecurityUtils.secure_compare(provided_password, password)
      end
    end
  end
end
