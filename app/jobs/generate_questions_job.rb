class GenerateQuestionsJob < ApplicationJob
  queue_as :default

  retry_on OpenaiClientService::ApiError, wait: 5.seconds, attempts: 3
  retry_on OpenaiClientService::Error, wait: 10.seconds, attempts: 2

  def perform(interview_session_id)
    interview_session = InterviewSession.find(interview_session_id)
    
    QuestionGeneratorService.call(interview_session)
    
    Rails.logger.info "Successfully generated questions for InterviewSession ##{interview_session_id}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "InterviewSession ##{interview_session_id} not found: #{e.message}"
  rescue OpenaiClientService::ConfigurationError => e
    Rails.logger.error "OpenAI configuration error: #{e.message}"
    raise # Don't retry configuration errors
  rescue StandardError => e
    Rails.logger.error "Failed to generate questions for InterviewSession ##{interview_session_id}: #{e.message}"
    raise
  end
end

