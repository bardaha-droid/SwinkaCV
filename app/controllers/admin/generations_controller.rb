module Admin
  class GenerationsController < BaseController
    def index
      @generations = Generation.order(created_at: :desc).limit(100)
    end

    def show
      @generation = Generation.find(params[:id])
    end
  end
end
