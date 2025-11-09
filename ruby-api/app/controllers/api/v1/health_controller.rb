module Api
  module V1
    class HealthController < ApplicationController
      def check
        render json: {
          status: "healthy",
          service: "ruby-api",
          timestamp: Time.current.to_i
        }
      end
    end
  end
end

