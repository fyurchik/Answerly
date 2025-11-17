class TranscribeAnswerJob < ApplicationJob
  queue_as :default

  retry_on TranscriptionService::ApiError, wait: 10.seconds, attempts: 3
  retry_on TranscriptionService::Error, wait: 20.seconds, attempts: 2

  def perform(answer_id)
    answer = Answer.find(answer_id)
    
    return unless answer.video.attached?
    return if answer.transcription.present?
    
    TranscriptionService.call(answer)
    
    Rails.logger.info "Successfully transcribed Answer ##{answer_id}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Answer ##{answer_id} not found: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Failed to transcribe Answer ##{answer_id}: #{e.message}"
    raise
  end
end

