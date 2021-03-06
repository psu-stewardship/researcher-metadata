module API::V1
  class APIController < ActionController::API
    before_action :authenticate_request!, except: [:profile]

    rescue_from ActiveRecord::RecordNotFound do |exception|
      render json: exception, status: 404
    end

    private

    def authenticate_request!
      if api_token
        api_token.increment_request_count
      else
        render json: {message: I18n.t('api.errors.not_authorized'), code: 401}, status: 401 unless api_token
      end
    end

    def api_token
      @api_token ||= APIToken.find_by(token: request.headers['HTTP_X_API_KEY'])
    end
  end
end
