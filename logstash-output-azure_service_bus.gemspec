Gem::Specification.new do |s|
  s.name          = 'logstash-output-azure_service_bus'
  s.version       = '0.2.2'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Send Logstash messages to Azure Service Bus.'
  s.homepage      = 'https://github.com/gharryg/logstash-output-azure_service_bus'
  s.authors       = ['Harrison Golden']
  s.email         = 'gharryg@mac.com'
  s.require_paths = ['lib']
  s.required_ruby_version = '>=2.5.0'

  # Files
  s.files = Dir['lib/**/*', '*.gemspec', '*.md', 'Gemfile', 'LICENSE']

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'output' }

  # Gem dependencies
  s.add_runtime_dependency 'faraday', '~> 1.9'
  s.add_runtime_dependency 'faraday-retry', '~> 1.0'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'logstash-core-plugin-api'
end
