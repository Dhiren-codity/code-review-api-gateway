class User < ApplicationRecord
  has_many :reviews, foreign_key: "author_id", dependent: :destroy
  has_many :comments, foreign_key: "author_id", dependent: :destroy

  validates :email, presence: true, uniqueness: true
end

