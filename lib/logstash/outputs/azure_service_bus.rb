require 'faraday'
require 'faraday/retry'
require 'json'
require 'logstash/outputs/base'

class LogStash::Outputs::AzureServiceBus < LogStash::Outputs::Base
  concurrency :single

  config_name 'azure_service_bus'

  config :service_bus_namespace, :validate => :string, :required => true
  config :service_bus_entity, :validate => :string, :required => true

  def register
    retry_options = {
      max: 3,
      interval: 1,
      interval_randomness: 0.5,
      backoff_factor: 2,
      retry_statuses: [429, 500],
      exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::RetriableResponse],
      methods: %i[get post],
      retry_block: ->(env, _options, retries, exception) { @logger.error("Error (#{exception}) for #{env.method.upcase} #{env.url} - #{retries + 1} retry(s) left") }
    }
    @token_conn = Faraday.new(
      url: 'http://169.254.169.254/metadata/identity/oauth2/token',
      params: { 'api-version' => '2018-02-01', 'resource' => 'https://servicebus.azure.net/' },
      headers: { 'Metadata' => 'true' },
      request: { timeout: 1 }
    ) do |f|
      f.request :retry, retry_options
    end
    @service_bus_conn = Faraday.new(
      url: "https://#{@service_bus_namespace}.servicebus.windows.net/#{@service_bus_entity}/",
      request: { timeout: 10 }
    ) do |f|
      f.request :retry, retry_options
    end
    refresh_access_token
  end

  def multi_receive(events)
    return if events.empty?

    send_events(events)
  end

  def send_events(events)
    messages = []
    events.each do |event|
      messages.append({ 'Body' => JSON.generate(event.to_hash), 'BrokerProperties' => { 'ContentType' => 'application/json' } })
    end
    post_messages(messages)
  end

  def post_messages(messages)
    refresh_access_token if access_token_needs_refresh?
    response = @service_bus_conn.post('messages') do |req|
      req.body = JSON.generate(messages)
      req.headers = { 'Authorization' => "Bearer #{@access_token}", 'Content-Type' => 'application/vnd.microsoft.servicebus.json' }
    end
    raise "Error while sending message to Service Bus: HTTP #{response.status}" if response.status != 201

    @logger.debug("Sent #{messages.length} message(s) to Service Bus")
  end

  def access_token_needs_refresh?
    Time.now.to_i - 60 > @access_token_expiration # Refresh the access token if it will expire within 60 seconds.
  end

  def refresh_access_token
    @logger.info('Refreshing Azure access token')
    begin
      response = @token_conn.get
    rescue Faraday::ConnectionFailed => e
      @logger.error('Unable to connect to the Azure Instance Metadata Service')
      raise e
    end
    raise "Unable to fetch token: #{response.body}" if response.status != 200

    data = JSON.parse(response.body)
    @access_token = data['access_token']
    @access_token_expiration = data['expires_on'].to_i
  end
end
