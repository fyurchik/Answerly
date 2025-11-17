class TranscriptionService
  class Error < StandardError; end
  class ApiError < Error; end
  class ConfigurationError < Error; end

  attr_reader :answer

  def self.call(answer)
    new(answer).call
  end

  def initialize(answer)
    validate_configuration!
    @answer = answer
  end

  def call
    return unless answer.video.attached?

    transcription_text = transcribe_video

    if transcription_text.present?
      answer.update!(transcription: transcription_text)
      Rails.logger.info "Transcribed Answer ##{answer.id}"
    end

    transcription_text
  end

  private

  def transcribe_video
    video_file = download_video

    response = send_to_elevenlabs(video_file)

    cleanup_temp_file(video_file)

    response.dig("text")
  rescue StandardError => e
    cleanup_temp_file(video_file) if video_file
    Rails.logger.error "Transcription failed for Answer ##{answer.id}: #{e.message}"
    raise ApiError, "Transcription failed: #{e.message}"
  end

  def download_video
    temp_file = Tempfile.new(['answer', '.webm'])
    temp_file.binmode

    answer.video.download do |chunk|
      temp_file.write(chunk)
    end

    temp_file.rewind
    temp_file
  end

  def send_to_elevenlabs(video_file)
    uri = URI("https://api.elevenlabs.io/v1/speech-to-text")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 300
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.path)
    request['xi-api-key'] = ENV.fetch('ELEVENLABS_API_KEY')
    request['Content-Type'] = 'multipart/form-data'

    form_data = [
      ['file', File.open(video_file.path), { filename: 'answer.webm', content_type: 'video/webm' }],
      ['model_id', 'scribe_v2']
    ]

    request.set_form(form_data, 'multipart/form-data')

    response = http.request(request)

    handle_response(response)
  end

  def handle_response(response)
    parsed_response = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      error_message = parsed_response.dig("error", "message") || parsed_response["detail"] || "Unknown error"
      raise ApiError, "ElevenLabs API error: #{error_message}"
    end

    parsed_response
  rescue JSON::ParserError => e
    raise ApiError, "Failed to parse ElevenLabs response: #{e.message}"
  end

  def validate_configuration!
    unless ENV["ELEVENLABS_API_KEY"].present?
      raise ConfigurationError, "ELEVENLABS_API_KEY environment variable is not set"
    end
  end

  def cleanup_temp_file(file)
    file&.close
    file&.unlink
  end
end

