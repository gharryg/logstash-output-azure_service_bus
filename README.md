# logstash-output-azure_service_bus

This plugin allows you to stream events from [Logstash](https://github.com/elastic/logstash) to a topic or queue in [Azure Service Bus](https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview). Currently, the only supported authentication mechanism is using [managed identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) which means this plugin must be run in an Azure compute environment. The entire Logstash event (not just the message) is passed to Service Bus with a content type of `application/json`.

This plugin is hosted on RubyGems.org: [https://rubygems.org/gems/logstash-output-azure_service_bus](https://rubygems.org/gems/logstash-output-azure_service_bus)

## Install
To install, use the plugin tool that is part of your Logstash installation:
```
$LOGSTASH_PATH/bin/logstash-plugin install logstash-output-azure_service_bus
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
There is one optional setting (`messageid_field`) which sets the Service Bus `MessageId` value to an existing, unique field. If this setting is not used, Service Bus will generate an id when the message is created.  The value of the provided field _must_ be unique or Service Bus will reject the message. A sample config might look like:
```
input { ... }
filter {
    uuid {
        target => "[@metadata][uuid]"
    }
}
output {
    azure_service_bus {
        service_bus_namespace => "service-bus-name"
        service_bus_entity => "queue-or-topic-name"
        messageid_field => "[@metadata][uuid]"
    }
    elasticsearch {
        ...
        document_id => "%{[@metadata][uuid]}"
    }
}
```

## Retry
This plugin will retry sending messages _indefinitely_ if Service Bus times out or returns a [documented bad response](https://docs.microsoft.com/en-us/rest/api/servicebus/send-message-batch#response-codes) (except 400). To avoid idempotence issues, you should enable duplicate detection on the destination queue or topic.
