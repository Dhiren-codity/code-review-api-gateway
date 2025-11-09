class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_request

  private

  def authenticate_request
    token = request.headers["Authorization"]&.split(" ")&.last
    return head :unauthorized unless token

    begin
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
      @current_user = User.find(decoded[0]["user_id"])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      head :unauthorized
    end
  end

  def current_user
    @current_user
  end
end

