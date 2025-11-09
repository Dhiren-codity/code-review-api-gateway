class User < ApplicationRecord
  has_secure_password

  has_many :reviews, foreign_key: "author_id", dependent: :destroy
  has_many :comments, foreign_key: "author_id", dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, length: {minimum: 8}, if: -> { new_record? || !password.nil? }
  validates :name, presence: true
end

