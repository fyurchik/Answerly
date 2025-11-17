class HeygenWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = JSON.parse(request.raw_post)
    event = payload["event_type"] || payload.dig("webhook", "event_type")
    event_data = payload["event_data"] || payload.dig("webhook", "event_data")

    return head :ok if event == "avatar_video_gif.success"

    if event == "avatar_video.success"
      video_id = event_data["video_id"]
      video_url = event_data["url"] || event_data["video_share_page_url"]

      question = Question.find_by(video_id: video_id)

      if question
        question.update!(video_url: video_url)
      else
        Rails.logger.warn "No question found with video_id: #{video_id}"
      end
    end

    head :ok
  rescue JSON::ParserError => e
    head :bad_request
  end
end

