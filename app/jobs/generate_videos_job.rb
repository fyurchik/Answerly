class GenerateVideosJob < ApplicationJob
  queue_as :default

  retry_on HeygenClientService::ApiError, wait: 10.seconds, attempts: 3
  retry_on HeygenClientService::Error, wait: 20.seconds, attempts: 2

  def perform(interview_session_id)
    interview_session = InterviewSession.find(interview_session_id)
    questions = interview_session.questions.where(video_id: nil)

    return if questions.empty?

    Rails.logger.info "Generating videos for #{questions.count} questions"

    questions.each do |question|
      HeygenVideoService.call(question)
      sleep(0.5)
    end

    Rails.logger.info "Successfully generated videos for InterviewSession ##{interview_session_id}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "InterviewSession ##{interview_session_id} not found: #{e.message}"
  rescue HeygenClientService::ConfigurationError => e
    Rails.logger.error "HeyGen configuration error: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Failed to generate videos for InterviewSession ##{interview_session_id}: #{e.message}"
    raise
  end
end

