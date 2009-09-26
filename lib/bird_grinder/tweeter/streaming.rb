require 'bird_grinder/tweeter/stream_processor'

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
      
      def initialize(parent)
        @parent = parent
        logger.debug "Initializing Streaming Support"
      end
      
      # Start processing the sample stream
      #
      # @param [Hash] opts extra options for the query
      def sample(opts = {})
        get(:sample, opts)
      end
      
      # Start processing the filter stream
      #
      # @param [Hash] opts extra options for the query
      def filter(opts = {})
        get(:filter, opts)
      end
      
      # Start processing the filter stream with a given follow
      # argument.
      #
      # @param [Array] args what to follow, joined with ","
      def follow(*args)
        opts = args.extract_options!
        opts[:follow] = args.join(",")
        opts[:path] = :filter
        get(:follow, opts)
      end
      
      # Starts tracking a specific query.
      # 
      # @param [Hash] opts extra options for the query
      def track(query, opts = {})
        opts[:track] = query
        opts[:path] = :filter
        get(:track, opts)
      end
      
      protected
      
      def get(name, opts = {}, attempts = 0)
        logger.debug "Getting stream #{name} w/ options: #{opts.inspect}"
        path = opts.delete(:path)
        processor = StreamProcessor.new(@parent, name)
        http_opts = {
          :head => {'Authorization' => @parent.auth_credentials}
        }
        http_opts[:query] = opts if opts.present?
        url = streaming_base_url / api_version.to_s / "statuses" / "#{path || name}.json"
        http = EventMachine::HttpRequest.new(url).get(http_opts)
        http.stream(&processor.method(:receive_chunk))
      end
      
    end
  end
end