class InterviewSession < ApplicationRecord
  belongs_to :user
  has_one_attached :resume

  # Validations
  validates :title, presence: true
  validates :interview_category, presence: true
  validates :position_level, presence: true
  validate :resume_validation

  # Enums for categories and levels
  INTERVIEW_CATEGORIES = [
    'General',
    'Technical',
    'Behavioral',
    'System Design',
    'Coding',
    'Leadership'
  ].freeze

  POSITION_LEVELS = [
    'Intern',
    'Junior',
    'Mid-Level',
    'Senior',
    'Lead',
    'Principal',
    'Executive'
  ].freeze

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(interview_category: category) if category.present? }

  private

  def resume_validation
    return unless resume.attached?

    # Check file size
    if resume.blob.byte_size > 5.megabytes
      errors.add(:resume, 'must be less than 5MB')
    end

    # Check content type
    unless resume.content_type == 'application/pdf'
      errors.add(:resume, 'must be a PDF file')
    end
  end
end
