require "jwt"

class ApplicationController < ActionController::API
  before_action :authenticate_request

  private

  def authenticate_request
    auth_header = request.headers["Authorization"]
    return head :unauthorized unless auth_header

    token = auth_header.split(" ").last
    return head :unauthorized unless token

    begin
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
      user_id = decoded[0]["user_id"]
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      head :unauthorized
    end
  end

  def current_user
    @current_user
  end
end

