require 'bird_grinder/tweeter/stream_processor'
require 'cgi'

module BirdGrinder
  class Tweeter
    # A request implementation for the twitter streaming api that correctly:
    # 1) keeps connections alives
    # 2) reacts accordingly to errors
    # 3) handles tweets in an evented way
    #
    # It's built around em-http-request internally but also makes use of BirdGrinder::Tweeter
    # and BirdGrinder::Tweeter::Streaming to provide a nice, user friendly interface.
    class StreamingRequest
      is :loggable
      
      # Values / rates as suggested in the twitter api.
      INITIAL_DELAYS   = {:http => 10,  :network => 0.25}
      MAX_DELAYS       = {:http => 240, :network => 16}
      DELAY_CALCULATOR = {
        :http    => L { |v| v * 2 },
        :network => L { |v| v + INITIAL_DELAYS[:network] }
      }
      
      # Creates a streaming request.
      #
      # @param [BirdGrinder::Tweeter] parent the tweeter parent class
      # @param [Sybol, String] name the name of the stream type
      # @param [Hash] options The options for this request
      # @option options [Symbol, String] :path the path component used for the streaming api e.g. sample for filter.
      # @options options [Object] :metadata generic data to be attached to received tweets
      def initialize(parent, name, options = {})
        logger.debug "Creating stream '#{name}' with options: #{options.inspect}"
        @parent         = parent
        @name           = name
        @path           = options.delete(:path) || name
        @metadata       = options.delete(:metadata) || {}
        @options        = options
        @failure_delay  = nil
        @failure_count  = 0
        @failure_reason = nil
      end
      
      # Starts the streaming connection
      def perform
        logger.debug "Preparing to start stream"
        @stream_processor = nil
        type = request_method
        http = EventMachine::HttpRequest.new(full_url).send(type, http_options(type, request))
        authorization_method.add_header_to(http)
        # Handle failures correctly so we can back off
        @current_request = http
        http.errback  { fail!(:network)}
        http.callback { http.response_header.status > 299 ? fail!(:http) : perform }
        http.stream { |c| receive_chunk(c) }
      end
      
      # Process a failure and responds accordingly.
      # 
      # @param [Symbol] type the type of error, one of :http or :network
      def fail!(type)
        suffix = type == :http ? " (Error Code #{@current_request.response_header.status})" : ""
        logger.debug "Streaming failed with #{type}#{suffix}"
        if @failure_count == 0 || @failure_reason != type
          logger.debug "Instantly restarting (#{@failure_count == 0  ? "First failure" : "Different type of failure"})"
          EM.next_tick { perform }
        else
          @failure_delay ||= INITIAL_DELAYS[type]
          logger.debug "Restarting stream in #{@failure_delay} seconds"
          logger.debug "Adding timer to restart in #{@failure_delay} seconds"
          EM.add_timer(@failure_delay) { perform }
          potential_new_delay = DELAY_CALCULATOR[type].call(@failure_delay)
          @failure_delay = [potential_new_delay, MAX_DELAYS[type]].min
          logger.debug "Next delay is #{@failure_delay}"
        end
        @failure_count += 1
        @failure_reason = type
        logger.debug "Failed #{@failure_count} times with #{@failure_reason}"
      end
      
      # Returns the current stream processor, creating a new one if it hasn't been initialized yet.
      def stream_processor
        @stream_processor ||= StreamProcessor.new(@parent, @name, @metadata)
      end
      
      # Processes a chunk of the incoming request, parsing it with the stream
      # processor as well as resetting anything that is used to track failure
      # (as a chunk implies that it's successful)
      #
      # @param [String] c the chunk of data to receive
      def receive_chunk(c)
        return unless @current_request.response_header.status == 200
        if !@failure_reason.nil?
          @failure_reason = nil
          @failure_delay  = nil
          @failure_count  = 0
        end
        stream_processor.receive_chunk(c)
      end
      
      # Returns a set of options that apply to the request no matter
      # what method is used to send the request. It's important that
      # this is used for credentials as well as making sure there is
      # no timeout on the connection
      def default_request_options(r)
        {:timeout => 0, :head => {}}
      end
      
      # Returns normalized http options for the current request, built
      # on top of default_request_options and a few other details.
      #
      # @param [Symbol] type the type of request - :post or :get
      # @param [EventMachine::HttpRequest] the request itself
      def http_options(type, request)
        base = self.default_request_options
        if @options.present?
          if type == :get
            base[:query] = @options
          else
            base[:head]['Content-Type'] = "application/x-www-form-urlencoded"
            base[:body] = body = {}
            @options.each_pair { |k,v| body[CGI.escape(k.to_s)] = CGI.escape(v) }
          end
        end
        base
      end
      
      # Returns the correct http method to be used for the current path.
      def request_method
        {:filter   => :post,
         :sample   => :get,
         :firehose => :get,
         :retweet  => :get
        }.fetch(@path, :get)
      end
      
      # Returns the full streaming api associated with this url.
      def full_url
        @full_url ||= (Streaming.streaming_base_url / Streaming.api_version.to_s / "statuses" / "#{@path}.json")
      end
      
      def authorization_method
        @authorization_method ||= BasicAuthorization.new
      end
      
    end
  end
end