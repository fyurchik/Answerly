class Question < ApplicationRecord
  belongs_to :interview_session
  has_one :answer, dependent: :destroy
  has_one_attached :attachment

  validates :content, presence: true
end
