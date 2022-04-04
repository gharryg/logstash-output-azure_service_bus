Gem::Specification.new do |s|
  s.name          = 'logstash-output-azure_service_bus'
  s.version       = '0.1.1'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Send Logstash messages to Azure Service Bus.'
  s.homepage      = 'https://github.com/gharryg/logstash-output-azure_service_bus'
  s.authors       = ['Harrison Golden']
  s.email         = 'gharryg@mac.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*', '*.gemspec', '*.md', 'Gemfile', 'LICENSE']

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'output' }

  # Gem dependencies
  s.add_runtime_dependency 'faraday'
  s.add_runtime_dependency 'faraday-retry'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'logstash-core-plugin-api'
  s.add_development_dependency 'logstash-devutils'
end
