require 'kafka'

module KafkaHelper

  # To start Kafka with Topic "fission.events"
  # zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties
  # kafka-server-start.sh /usr/local/kafka/config/server.properties
  # kafka-server-start.sh /usr/local/kafka/config/server1.properties
  # kafka-topics.sh --zookeeper localhost:2181 --create --topic fission.events --partitions 1 --replication-factor 1

  class DistQueue   
    
    def push(message)        
      $kafka_producers.push(Kafka::Message.new(message))
    end

    def bpop()
      consumer = Kafka::Consumer.new(Rails.application.config.kafka)
      consumer.loop do |messages|
        messages.each do |message|
          yield message.payload
        end
      end
    end

  end


  class EventsQueue < DistQueue
  end
  
end
