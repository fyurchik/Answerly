class OverallFeedback < ApplicationRecord
  belongs_to :interview_session

  validates :interview_session, presence: true
  validates :overall_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :summary, presence: true
  validates :key_strengths, presence: true
  validates :areas_for_improvement, presence: true
end
