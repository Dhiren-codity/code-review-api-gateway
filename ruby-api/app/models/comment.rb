class Comment < ApplicationRecord
  validates :content, presence: true

  belongs_to :review
  belongs_to :author, class_name: "User", optional: true
end

