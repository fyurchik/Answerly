class HeygenWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.info "Received HeyGen webhook: #{request.raw_post}"
    payload = JSON.parse(request.raw_post)
    event = payload["event_type"] || payload.dig("webhook", "event_type")
    event_data = payload["event_data"] || payload.dig("webhook", "event_data")

    Rails.logger.info "HeyGen webhook event: #{event}"
    Rails.logger.info "HeyGen webhook data: #{event_data.inspect}"

    return head :ok if event == "avatar_video_gif.success"

    if event == "avatar_video.success"
      video_id = event_data["video_id"]
      video_url = event_data["url"] || event_data["video_share_page_url"]

      Rails.logger.info "Processing video success: id=#{video_id}, url=#{video_url}"

      question = Question.find_by(video_id: video_id)

      if question
        question.update!(video_url: video_url)
        Rails.logger.info "Updated Question ##{question.id} with video_url: #{video_url}"
      else
        Rails.logger.warn "No question found with video_id: #{video_id}"
      end
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse HeyGen webhook: #{e.message}"
    head :bad_request
  end
end

