module BirdGrinder
  class Tweeter
    class Search
      is :loggable
      
      # 30 seconds between searches
      DELAY_SEARCH = 30
      
      cattr_accessor :search_base_url
      @@search_base_url = "http://search.twitter.com/"
      
      def initialize(parent)
        logger.debug "Initializing Search"
        @parent = parent
      end
      
      # Uses the twitter search api to look up a
      # given query. If :repeat is given, it will
      # repeat indefinitely, getting only new messages each
      # iteration.
      #
      # @param [String] query what you wish to search for
      # @param [Hash] opts options for the query string (except for :repeat)
      # @option opts [Boolean] :repeat if present, will repeat indefinitely.
      def search_for(query, opts = {})
        logger.info "Searching for #{query.inspect}"
        opts = opts.dup
        repeat = opts.delete(:repeat)
        perform_search(query, opts) do |response|
          if repeat && response.max_id?
            logger.info "Scheduling next search iteration for #{query.inspect}"
            EM.add_timer(DELAY_SEARCH) do
              opts[:repeat]   = true
              opts[:since_id] = response.max_id
              search_for(query, opts)
            end
          end
        end
      end
      
      protected
      
      def perform_search(query, opts = {}, &blk)
        url = search_base_url / "search.json"
        query_opts = opts.stringify_keys
        query_opts["q"] = query.to_s.strip
        query_opts["rpp"] ||= 100
        http = EventMachine::HttpRequest.new(url).get(:query => query_opts)
        http.callback do
          response = parse_response(http)
          blk.call(response) if blk.present?
          if response.results?
            response.results.each do |result|
              result.type = :search
              @parent.delegate.receive_message(:incoming_search, result)
            end
          end
        end
      end
      
      def parse_response(http)
        response = Yajl::Parser.parse(http.response)
        response.to_nash.normalized
      rescue Yajl::ParseError => e
        logger.error "Couldn't parse search response, error:\n#{e.message}"
        BirdGrinder::Nash.new
      end
      
    end
  end
end