module BirdGrinder
  # A simple BirdGrinder::Base subclass which has a
  # focus on processing tweets from a stream.
  class StreamHandler < Base
    
    class << self
      
      # Do something on tweet's from a given stream
      # @param [Symbol] the stream name, e.g. :filter / :sample
      def tweet_from_stream(name, &blk)
        on_event(:incoming_stream) do
          instance_eval(&blk) if options.streaming_source == name && options.stream_type == :tweet
        end
      end
      
      # Do something on delete's from a given stream
      # @param [Symbol] the stream name, e.g. :filter / :sample
      def delete_from_stream(name, &blk)
        on_event(:incoming_stream) do
          instance_eval(&blk) if options.streaming_source == name && options.stream_type == :delete
        end
      end
      
      # Do something on rate limit's from a given stream
      # @param [Symbol] the stream name, e.g. :filter / :sample
      def rate_limit_from_stream(name, &blk)
        on_event(:incoming_stream) do
          instance_eval(&blk) if options.streaming_source == name && options.stream_type == :limit
        end
      end
      
      %w(sample filter follow track).each do |type|
        define_method(type.to_sym) do |*args|
          BirdGrinder::Loader.once_running do
            streaming = BirdGrinder::Client.current.tweeter.streaming
            streaming.send(type.to_sym, *args)
          end
        end
      end
      
    end 
    
  end
end