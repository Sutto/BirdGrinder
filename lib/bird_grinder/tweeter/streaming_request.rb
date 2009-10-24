require 'bird_grinder/tweeter/stream_processor'
require 'cgi'

module BirdGrinder
  class Tweeter
    class StreamingRequest
      is :loggable
      
      INITIAL_DELAYS = {:http => 10,  :network => 0.25}
      MAX_DELAYS     = {:http => 240, :network => 16}
      DELAY_CALCULATOR = {
        :http    => L { |v| v * 2 },
        :network => L { |v| v + INITIAL_DELAYS[:network] }
      }
      
      def initialize(parent, name, options = {})
        logger.debug "Creating stream '#{name}' with options: #{options.inspect}"
        @parent         = parent
        @name           = name
        @path           = options.delete(:path) || :name
        @metadata       = options.delete(:metadata) || {}
        @options        = options
        @failure_delay  = nil
        @failure_count  = 0
        @failure_reason = nil
      end
      
      def perform
        logger.debug "Preparing to start stream"
        @stream_processor = nil
        type = request_method
        http = create_request.send(type, http_options(type))
        # Handle failures correctly so we can back off
        @current_request = http
        http.errback  { fail!(:network)}
        http.callback { http.response_header.status > 299 ? fail!(:http) : perform }
        http.stream { |c| receive_chunk(c) }
      end
      
      def fail!(type)
        logger.debug "Streaming failed with #{type}"
        if @failure_count == 0 || @failure_reason != type
          logger.debug "Instantly restarting (#{@failure_count == 0  ? "First failure" : "Different type"})"
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
      
      def create_request
        EventMachine::HttpRequest.new(full_url)
      end
      
      def stream_processor
        @stream_processor ||= StreamProcessor.new(@parent, @name, @metadata)
      end
      
      def receive_chunk(c)
        return unless @current_request.response_header.status == 200
        if !@failure_reason.nil?
          @failure_reason = nil
          @failure_delay  = nil
          @failure_count  = 0
        end
        stream_processor.receive_chunk(c)
      end
      
      def default_request_options
        {:head => {'Authorization' => @parent.auth_credentials}}
      end
      
      def http_options(type)
        base = self.default_request_options
        if @options.present?
          if type == :get
            base[:query] = @options
          else
            base[:head].merge! 'Content-Type'  => "application/x-www-form-urlencoded"
            base[:body] = body = {}
            @options.each_pair { |k,v| body[CGI.escape(k.to_s)] = CGI.escape(v) }
          end
        end
        base
      end
      
      def request_method
        {:filter   => :post,
         :sample   => :get,
         :firehose => :get,
         :retweet  => :get
        }.fetch(@path, :get)
      end
      
      def full_url
        @full_url ||= (Streaming.streaming_base_url / Streaming.api_version.to_s / "statuses" / "#{@path}.json")
      end
      
    end
  end
end