# require 'singleton'

module KafkaHelper

  # zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties
  # kafka-server-start.sh /usr/local/kafka/config/server.properties
  # kafka-topics.sh --zookeeper localhost:2181 --create --topic fission.events --partitions 1 --replication-factor 1

  class DistQueue   
    
    def push(message)  
      
      @producer = Poseidon::Producer.new([@options[:url]], 'fission_producer') unless @producer

      # @producer = Kafka::Producer.new(@options) unless @producer
      # @producer.push(Kafka::Message.new(message))
    end

    def consume()
      uri = @options[:url].split(':')
      @consumer = Poseidon::PartitionConsumer.new('fission_consumer', uri[0], uri[1], @topic, 0, :earliest_offset)


      # @consumer = Kafka::consumer.new(@options) unless @consumer

      loop do
        messages = @consumer.fetch
        messages.each do |message|
          yield message.value
        end
      end
    end

  end


  class EventsQueue < DistQueue

    def initialize
      @topic = 'fission.events'
      @options = Rails.application.config.kafka
      @options[:topic] = @topic
    end

  end
end
