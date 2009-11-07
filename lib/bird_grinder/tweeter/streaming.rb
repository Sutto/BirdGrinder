require 'bird_grinder/tweeter/streaming_request'

module BirdGrinder
  class Tweeter
    # Basic support for the twitter streaming api. Provides
    # access to sample, filter, follow and track. Note that
    # it will dispatch messages as :incoming_stream, with
    # options.streaming_source set to the stream origin.
    class Streaming
      is :loggable
      
      cattr_accessor :streaming_base_url, :api_version
      self.streaming_base_url = "http://stream.twitter.com/"
      self.api_version        = 1
      
      attr_accessor  :parent
      
      # Initializes a streaming subclient for a given tweeter
      #
      # @param [BirdGrinder::Tweeter] parent the parent tweeter which we use to dispatch events.
      def initialize(parent)
        @parent = parent
        logger.debug "Initializing Streaming Support"
      end
      
      # Start processing the sample stream
      #
      # @param [Hash] opts extra options for the query
      def sample(opts = {})
        stream(:sample, opts)
      end
      
      # Start processing the filter stream
      #
      # @param [Hash] opts extra options for the query
      def filter(opts = {})
        stream(:filter, opts)
      end
      
      # Start processing the filter stream with a given follow
      # argument.
      #
      # @param [Array] args what to follow, joined with ","
      def follow(*args)
        opts = args.extract_options!
        opts[:follow] = args.join(",")
        opts[:path] = :filter
        stream(:follow, opts)
      end
      
      # Starts tracking a specific query.
      # 
      # @param [Hash] opts extra options for the query
      def track(query, opts = {})
        opts[:track] = query
        opts[:path] = :filter
        stream(:track, opts)
      end
      
      protected
      
      def stream(name, opts = {})
        req = StreamingRequest.new(@parent, name, opts)
        yield req if block_given?
        req.perform
        req
      end
      
      def get(name, opts = {}, attempts = 0)
        
      end
      
    end
  end
end