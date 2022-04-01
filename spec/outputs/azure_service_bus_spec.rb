require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/azure_service_bus'
require 'logstash/codecs/plain'

describe LogStash::Outputs::AzureServiceBus do
  let(:sample_event) { LogStash::Event.new }
  let(:output) { LogStash::Outputs::AzureServiceBus.new }

  before do
    output.register
  end

  describe 'receive message' do
    subject { output.receive(sample_event) }

    it 'returns a string' do
      expect(subject).to eq('Event received')
    end
  end
end
