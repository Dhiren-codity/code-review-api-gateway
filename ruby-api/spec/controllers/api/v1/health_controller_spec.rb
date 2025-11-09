require "rails_helper"

RSpec.describe Api::V1::HealthController, type: :controller do
  describe "GET #check" do
    it "returns healthy status" do
      get :check
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("healthy")
      expect(json_response["service"]).to eq("ruby-api")
    end
  end
end

