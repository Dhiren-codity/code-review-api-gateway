class Review < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :status, inclusion: {in: %w[pending approved rejected]}

  belongs_to :author, class_name: "User", optional: true
  has_many :comments, dependent: :destroy
end

