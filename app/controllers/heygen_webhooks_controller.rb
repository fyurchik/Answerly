class HeygenWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = parse_payload
    event = payload["event_type"] || payload.dig("webhook", "event_type")
    event_data = payload["event_data"] || payload.dig("webhook", "event_data")

    return head :ok if event == "avatar_video_gif.success"

    handle_video_success(event_data) if event == "avatar_video.success"

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def parse_payload
    JSON.parse(request.raw_post)
  end

  def handle_video_success(event_data)
    video_id = event_data["video_id"]
    video_url = event_data["url"] || event_data["video_share_page_url"]

    question = Question.find_by(video_id: video_id)
    return unless question

    question.update!(video_url: video_url)
    notify_user_if_ready(question.interview_session)
  end

  def notify_user_if_ready(interview_session)
    return unless interview_session.ready?

    ActionCable.server.broadcast(
      UserChannel.broadcasting_for(interview_session.user),
      {
        type: 'videos_ready',
        title: 'Interview Ready!',
        message: "All videos are ready for: #{interview_session.title}",
        link_url: interview_session_url(interview_session, host: app_host),
        link_text: 'Start Interview',
        icon: 'video'
      }
    )
  end

  def app_host
    ENV['HOST'] || 'localhost:3000'
  end
end
