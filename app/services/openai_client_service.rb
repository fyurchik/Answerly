class OpenaiClientService
  class Error < StandardError; end
  class ApiError < Error; end
  class ConfigurationError < Error; end

  attr_reader :messages, :options, :client

  def self.call(messages:, **options)
    new(messages: messages, **options).call
  end

  def initialize(messages:, **options)
    validate_configuration!
    @messages = messages
    @options = default_options.merge(options)
    @client = OpenAI::Client.new
  end

  def call
    make_request
  end

  private

  def make_request
    response = client.chat(
      parameters: {
        model: options[:model],
        messages: messages,
        temperature: options[:temperature],
        max_tokens: options[:max_tokens]
      }
    )

    extract_content(response)
  rescue Faraday::Error => e
    raise ApiError, "OpenAI API request failed: #{e.message}"
  rescue StandardError => e
    raise Error, "Unexpected error: #{e.message}"
  end

  def extract_content(response)
    if response["error"]
      raise ApiError, "OpenAI API error: #{response['error']['message']}"
    end

    response.dig("choices", 0, "message", "content")
  end

  def default_options
    {
      model: ENV.fetch("OPENAI_MODEL", "gpt-4o-mini"),
      temperature: ENV.fetch("OPENAI_TEMPERATURE", "0.7").to_f,
      max_tokens: ENV.fetch("OPENAI_MAX_TOKENS", "2000").to_i
    }
  end

  def validate_configuration!
    unless ENV["OPENAI_API_KEY"].present?
      raise ConfigurationError, "OPENAI_API_KEY environment variable is not set"
    end
  end
end

