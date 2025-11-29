class GenerateFeedbackJob < ApplicationJob
  queue_as :default

  retry_on OpenaiClientService::ApiError, wait: 10.seconds, attempts: 3
  retry_on OpenaiClientService::Error, wait: 20.seconds, attempts: 2

  def perform(interview_session_id)
    interview_session = InterviewSession.find(interview_session_id)

    return if interview_session.overall_feedback.present?

    FeedbackGeneratorService.call(interview_session)
    notify_user(interview_session)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "InterviewSession ##{interview_session_id} not found: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Failed to generate feedback for InterviewSession ##{interview_session_id}: #{e.message}"
    raise
  end

  private

  def notify_user(interview_session)
    score = interview_session.overall_feedback.overall_score

    ActionCable.server.broadcast(
      UserChannel.broadcasting_for(interview_session.user),
      {
        type: 'feedback_ready',
        title: 'Feedback Ready!',
        message: "Your interview feedback is ready. Score: #{score}/100",
        link_url: Rails.application.routes.url_helpers.interview_session_feedback_url(
          interview_session,
          host: ENV['HOST'] || 'localhost:3000'
        ),
        link_text: 'View Feedback',
        icon: score_icon(score)
      }
    )
  end

  def score_icon(score)
    case score
    when 80..100 then 'star'
    when 60...80 then 'check'
    when 40...60 then 'trending-up'
    else 'book'
    end
  end
end
