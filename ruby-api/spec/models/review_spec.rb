require "rails_helper"

RSpec.describe Review, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_inclusion_of(:status).in_array(%w[pending approved rejected]) }
  end

  describe "associations" do
    it { should belong_to(:author).class_name("User").optional }
    it { should have_many(:comments).dependent(:destroy) }
  end
end
