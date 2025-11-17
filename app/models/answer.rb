class Answer < ApplicationRecord
  belongs_to :question
  has_one_attached :video

  validates :question, presence: true
end
