module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session

    before_action :force_json

    private

    def force_json
      request.format = :json
    end
  end
end
