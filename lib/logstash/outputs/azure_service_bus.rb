require 'faraday'
require 'faraday/retry'
require 'json'
require 'logstash/outputs/base'

class LogStash::Outputs::AzureServiceBus < LogStash::Outputs::Base
  concurrency :single

  config_name 'azure_service_bus'

  config :service_bus_namespace, :validate => :string, :required => true
  config :service_bus_entity, :validate => :string, :required => true
  config :messageid_field, :validate => :string

  def register
    service_bus_retry_options = {
      max: Float::MAX, # Essentially retries indefinitely
      interval: 1,
      interval_randomness: 0.5,
      backoff_factor: 2,
      exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::RetriableResponse],
      methods: [], # Empty -> all methods
      retry_statuses: [401, 403, 404, 410, 429, 500], # https://docs.microsoft.com/en-us/rest/api/servicebus/send-message-batch#response-codes
      retry_block: lambda do |env, _options, _retries, exception|
        if env.status.nil?
          @logger.warn("Problem (#{exception}) for #{env.method.upcase} #{env.url}")
        else
          @logger.warn("Problem (HTTP #{env.status}) for #{env.method.upcase} #{env.url}")
        end
      end,
      retry_if: lambda do |env, _exc|
        refresh_access_token if env.status == 401
        true # Always retry
      end
    }
    @service_bus_conn = Faraday.new(
      url: "https://#{@service_bus_namespace}.servicebus.windows.net/#{@service_bus_entity}/",
      request: { timeout: 10 }
    ) do |conn|
      conn.request :retry, service_bus_retry_options
    end
    @access_token = ''
    refresh_access_token
  end

  def multi_receive(events)
    return if events.empty?

    send_events(events)
  end

  def send_events(events)
    messages = []
    events.each do |event|
      if @messageid_field.nil?
        messages.append({ 'Body' => JSON.generate(event.to_hash), 'BrokerProperties' => { 'ContentType' => 'application/json' } })
      else
        messages.append({ 'Body' => JSON.generate(event.to_hash), 'BrokerProperties' => { 'ContentType' => 'application/json', 'MessageId' => event.get(@messageid_field) } })
      end
    end
    post_messages(messages)
  end

  def post_messages(messages)
    response = @service_bus_conn.post('messages') do |req|
      req.body = JSON.generate(messages)
      req.headers = { 'Authorization' => "Bearer #{@access_token}", 'Content-Type' => 'application/vnd.microsoft.servicebus.json' }
    end
  rescue StandardError => e
    # Hopefully we never make it here and "throw away" messages since we have an agressive retry strategy.
    @logger.error("Error (#{e}) while sending message to Service Bus")
  else
    if response.status == 200
      @logger.debug("Sent #{messages.length} message(s) to Service Bus")
    else
      @logger.error("Error while sending message to Service Bus: HTTP #{response.status}")
    end
  end

  def refresh_access_token
    @logger.info('Refreshing Azure access token')
    begin
      response = Faraday.get('http://169.254.169.254/metadata/identity/oauth2/token', params: { 'api-version' => '2018-02-01', 'resource' => 'https://servicebus.azure.net/' }) do |req|
        req.headers = { 'Metadata' => 'true' }
        req.options.timeout = 4
      end
    rescue StandardError => e # We just catch everything and move on since @service_bus_conn will handle retries.
      @logger.error("Error while fetching access token: #{e}")
    else
      if response.status == 200
        data = JSON.parse(response.body)
        @access_token = data['access_token']
      else
        @logger.error("HTTP error when fetching access token: #{response.body}")
      end
    end
  end
end
