# logstash-output-azure_service_bus

This plugin allows you to stream events from [Logstash](https://github.com/elastic/logstash) to a topic or queue in [Azure Service Bus](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview). Currently, the only supported authentication mechanism is using [managed identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) which means this plugin must be run in an Azure compute environment. The entire Logstash event (not just the message) is passed to Service Bus with a content type of `application/json`.

This plugin is hosted on RubyGems.org: [https://rubygems.org/gems/logstash-output-azure_service_bus](https://rubygems.org/gems/logstash-output-azure_service_bus)

## Install
To install, use the plugin tool that is part of your Logstash installation:
```
$LOGSTASH_INSTALL/bin/logstash-plugin install logstash-output-azure_service_bus
```

## Pipeline Configuration
As mentioned above, the compute environment that Logstash is running in must have managed identity enabled. In addition, the managed identity should have permissions to send to the desired queue or topic - typically the `Azure Service Bus Data Sender` role.

Two settings in your Logstash pipeline are required:
```
output {
    azure_service_bus {
        service_bus_namespace => "service-bus-name"
        service_bus_entity => "queue-or-topic-name"
    }
}
```

## Service Bus Configuration
This plugin will retry sending messages if the Service Bus connection times out or returns a bad response. To avoid idempotence issues, you should enable duplicate detection on the destination queue or topic.
