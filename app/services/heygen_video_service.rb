class HeygenVideoService
  WEBHOOK_PATH = "/heygen/webhook"

  attr_reader :question, :text, :client, :avatar_id, :voice_id, :background_color, :width, :height

  def self.call(question, **options)
    new(question, **options).call
  end

  def initialize(question,
                 text: nil,
                 avatar_id: "Amelia_sitting_business_training_side",
                 voice_id: "e0cc82c22f414c95b1f25696c732f058",
                 background_color: "#008000",
                 width: 1280,
                 height: 720)
    @question = question
    @text = text || question.content
    @client = HeygenClientService.new
    @avatar_id = avatar_id
    @voice_id = voice_id
    @background_color = background_color
    @width = width
    @height = height
  end

  def call
    payload = {
      video_inputs: [
        {
          character: {
            type: "avatar",
            avatar_id: avatar_id,
            avatar_style: "normal"
          },
          voice: {
            type: "text",
            input_text: text,
            voice_id: voice_id
          },
          background: {
            type: "color",
            value: background_color
          }
        }
      ],
      dimension: {
        width: width,
        height: height
      },
      callback_url: callback_url
    }

    response = client.post("/v2/video/generate", payload)
    video_id = response.dig("data", "video_id")

    if video_id.present?
      question.update!(video_id: video_id)
    else
      Rails.logger.error "No video_id found in response"
    end

    video_id
  end

  private

  def callback_url
    host = ENV.fetch("HOST", "http://localhost:3000").strip
    host.chomp("/") + WEBHOOK_PATH
  end
end

