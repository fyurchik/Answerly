require 'net/http'
require 'json'
require 'openssl'

class HeygenClientService
  class Error < StandardError; end
  class ApiError < Error; end
  class ConfigurationError < Error; end

  BASE_URL = "https://api.heygen.com"

  attr_reader :api_key

  def initialize
    validate_configuration!
    @api_key = ENV.fetch("HEYGEN_API_KEY")
  end

  def post(endpoint, payload)
    uri = URI("#{BASE_URL}#{endpoint}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 120
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['X-Api-Key'] = api_key
    request.body = payload.to_json

    response = http.request(request)

    handle_response(response)
  rescue StandardError => e
    raise ApiError, "HeyGen API request failed: #{e.message}"
  end

  def get(endpoint)
    uri = URI("#{BASE_URL}#{endpoint}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.path)
    request['X-Api-Key'] = api_key

    response = http.request(request)

    handle_response(response)
  rescue StandardError => e
    raise ApiError, "HeyGen API request failed: #{e.message}"
  end

  private

  def validate_configuration!
    unless ENV["HEYGEN_API_KEY"].present?
      raise ConfigurationError, "HEYGEN_API_KEY environment variable is not set"
    end
  end

  def handle_response(response)
    parsed_response = JSON.parse(response.body)
    
    unless response.is_a?(Net::HTTPSuccess)
      error_message = parsed_response.dig("error", "message") || "Unknown error"
      raise ApiError, "HeyGen API error: #{error_message}"
    end
    
    parsed_response
  rescue JSON::ParserError => e
    raise ApiError, "Failed to parse HeyGen response: #{e.message}"
  end
end

