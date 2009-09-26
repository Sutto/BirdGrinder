require 'bird_grinder/tweeter/stream_processor'

module BirdGrinder
  class Tweeter
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
      
      def sample(opts = {})
        get(:sample, opts)
      end
      
      def filter(opts = {})
        get(:filter, opts)
      end
      
      def follow(*args)
        opts = args.extract_options!
        opts[:follow] = args.join(",")
        opts[:path] = :filter
        get(:follow, opts)
      end
      
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
          :on_response => processor.method(:receive_chunk),
          :head        => {'Authorization' => @parent.auth_credentials}
        }
        http_opts[:query] = opts if opts.present?
        url = streaming_base_url / api_version.to_s / "statuses" / "#{path || name}.json"
        http = EventMachine::HttpRequest.new(url).get(http_opts)
      end
      
    end
  end
end