module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_request, only: [:register, :login]

      def register
        @user = User.new(user_params)
        @user.password = params[:password]

        if @user.save
          render json: {
            message: "User created successfully",
            user: {
              id: @user.id,
              email: @user.email,
              name: @user.name
            }
          }, status: :created
        else
          render json: {
            error: "Registration failed",
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def login
        @user = User.find_by(email: params[:email])

        if @user && @user.authenticate(params[:password])
          render json: {
            message: "Login successful",
            user: {
              id: @user.id,
              email: @user.email,
              name: @user.name
            }
          }, status: :ok
        else
          render json: {
            error: "Invalid email or password"
          }, status: :unauthorized
        end
      end

      def logout
        render json: {
          message: "Logged out successfully"
        }, status: :ok
      end

      private

      def user_params
        params.permit(:email, :name, :password)
      end
    end
  end
end

