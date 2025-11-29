class InterviewSession < ApplicationRecord
  belongs_to :user
  has_many :questions, dependent: :destroy
  has_one :overall_feedback, dependent: :destroy
  has_one_attached :resume

  after_create :enqueue_question_generation

  # Validations
  validates :title, presence: true
  validates :interview_category, presence: true
  validates :position_level, presence: true
  validates :questions_count, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 20 }
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

  def ready?
    questions.all?(&:video_url?)
  end

  def answered?
    questions.all?{|question| question.answer.present? }
  end

  private

  def enqueue_question_generation
    GenerateQuestionsJob.perform_later(id)
  end

  def resume_validation
    return unless resume.attached?

    if resume.blob.byte_size > 5.megabytes
      errors.add(:resume, 'must be less than 5MB')
    end

    unless resume.content_type == 'application/pdf'
      errors.add(:resume, 'must be a PDF file')
    end
  end
end
