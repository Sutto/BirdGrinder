require 'uri'

module BirdGrinder
  # An asynchronous, delegate-based twitter client that uses
  # em-http-request and yajl on the backend. It's built to be fast,
  # minimal and easy to use.
  #
  # The delegate is simply any class - the tweeter will attempt to
  # call receive_message([Symbol], [BirdGrinder::Nash]) every time
  # it processes a message / item of some kind. This in turn makes
  # it easy to process items. Also, it will dispatch both
  # incoming (e.g. :incoming_mention, :incoming_direct_message) and
  # outgoing (e.g. :outgoing_tweet) events.
  #
  # It has support the twitter search api (via #search) and the currently-
  # alpha twitter streaming api (using #streaming) built right in.
  class Tweeter
    is :loggable, :delegateable
    
    require 'bird_grinder/tweeter/streaming'
    require 'bird_grinder/tweeter/search'
    
    VALID_FETCHES = [:direct_messages, :mentions]
    
    cattr_accessor :api_base_url
    self.api_base_url = "http://twitter.com/"
      
    attr_reader :auth_credentials
        
    # Initializes the tweeter with a given delegate. It will use
    # username and password from your settings file for authorization
    # with twitter.
    #
    # @param [Delegate] delegate the delegate class
    def initialize(delegate)
      check_auth!
      @auth_credentials = [BirdGrinder::Settings.username, BirdGrinder::Settings.password]
      delegate_to delegate
    end
    
    # Automates fetching mentions / direct messages at the same time.
    #
    # @param [Array<Symbol>] fetches what to load - :all for all fetches, or names of the fetches otherwise
    def fetch(*fetches)
      options = fetches.extract_options!
      fetches = VALID_FETCHES if fetches == [:all]
      (fetches & VALID_FETCHES).each do |fetch_type|
        send(fetch_type, options.dup)
      end
    end
    
    # Tells the twitter api to follow a specific user
    #
    # @param [String] user the screen_name of the user to follow
    # @param [Hash] opts extra options to pass in the query string
    def follow(user, opts = {})
      user = user.to_s.strip
      logger.info "Following '#{user}'"
      post("friendships/create.json", opts.merge(:screen_name => user)) do
        delegate.receive_message(:outgoing_follow, {:user => user}.to_nash)
      end
    end
    
    # Tells the twitter api to unfollow a specific user
    #
    # @param [String] user the screen_name of the user to unfollow
    # @param [Hash] opts extra options to pass in the query string
    def unfollow(user, opts = {})
      user = user.to_s.strip
      logger.info "Unfollowing '#{user}'"
      post("friendships/destroy.json", opts.merge(:screen_name => user)) do
        delegate.receive_message(:outgoing_unfollow, {:user => user}.to_nash)
      end
    end
    
    # Updates your current status on twitter with a specific message
    #
    # @param [String] message the contents of your tweet
    # @param [Hash] opts extra options to pass in the query string
    def tweet(message, opts = {})
      message = message.to_s.strip
      logger.debug "Tweeting #{message}"
      post("statuses/update.json", opts.merge(:status => message)) do |json|
        delegate.receive_message(:outgoing_tweet, status_to_args(json))
      end
    end
    
    # Sends a direct message to a given user
    #
    # @param [String] user the screen_name of the user you wish to dm
    # @param [String] text the text to send to the user
    # @param [Hash] opts extra options to pass in the query string
    def dm(user, text, opts = {})
      text = text.to_s.strip
      user = user.to_s.strip
      logger.debug "DM'ing #{user}: #{text}"
      post("direct_messages/new.json", opts.merge(:user => user, :text => text)) do
        delegate.receive_message(:outgoing_direct_message, {:user => user, :text => text}.to_nash)
      end
    end
    
    # Returns an instance of BirdGrinder::Tweeter::Streaming,
    # used for accessing the alpha streaming api for twitter.
    #
    # @see BirdGrinder::Tweeter::Streaming
    def streaming
      @streaming ||= Streaming.new(self)
    end
    
    # Uses the twitter search api to look up a given
    # query, with a set of possible options.
    #
    # @param [String] query the query you wish to search for
    # @param [Hash] opts the opts to query, all except :repeat are sent to twitter.
    # @option opts [Boolean] :repeat repeat the query indefinitely, fetching new messages each time
    def search(query, opts = {})
      @search ||= Search.new(self)
      @search.search_for(query, opts)
    end
    
    # Sends a correctly-formatted at reply to a given user.
    # If the users screen_name isn't at the start of the tweet,
    # it will be appended accordingly.
    #
    # @param [String] user the user to reply to's screen name
    # @param [String] test the text to reply with
    # @param [Hash] opts the options to pass in the query string
    def reply(user, text, opts = {})
      user = user.to_s.strip
      text = text.to_s.strip
      text = "@#{user} #{text}".strip unless text =~ /^\@#{user}\b/i
      tweet(text, opts)
    end
    
    # Asynchronously fetches the current users (as specified by your settings)
    # direct messages from the twitter api
    #
    # @param [Hash] opts options to pass in the query string
    def direct_messages(opts = {})
      logger.debug "Fetching direct messages..."
      get("direct_messages.json", opts) do |dms|
        logger.debug "Fetched a total of #{dms.size} direct message(s)"
        dms.each do |dm|
          delegate.receive_message(:incoming_direct_message, status_to_args(dm, :direct_message))
        end
      end
    end
    
    # Asynchronously fetches the current users (as specified by your settings)
    # mentions from the twitter api
    #
    # @param [Hash] opts options to pass in the query string
    def mentions(opts = {})
      logger.debug "Fetching mentions..."
      get("statuses/mentions.json", opts) do |mentions|
        logger.debug "Fetched a total of #{mentions.size} mention(s)"
        mentions.each do |status|
          delegate.receive_message(:incoming_mention, status_to_args(status, :mention))
        end
      end
    end
    
    # Gets a list ids who are following a given user id / screenname
    #
    # @param [String,Integer] id the user id or screen name to get followers for.
    # @param [Hash] opts extra options to pass in the query string.
    # @option opts [Integer] :cursor the cursor offset in the results
    def follower_ids(id, opts = {})
      cursor_list = []
      if opts[:cursor].present?
        logger.info "Getting page w/ cursor #{opts[:cursor]} for #{id}"
        get_followers_page(id, opts) do |res|
          results                 = BirdGrinder::Nash.new
          results.cursor          = opts[:cursor]
          results.user_id         = id
          results.ids             = res.ids? ? res.ids : []
          results.next_cursor     = res.next_cursor || 0
          results.previous_cursor = res.previous_cursor || 0
          results.all = (res.previous_cursor == 0 && res.next_cursor == 0)
          delegate.receive_message(:incoming_follower_ids, results)
        end
      else
        logger.info "Getting all followers for #{id}"
        get_followers(id, opts.merge(:cursor => -1), {
          :user_id => id,
          :all     => true,
          :ids     => []
        }.to_nash)
      end
    end
        
    protected
    
    def get_followers(id, opts, nash)
      get_followers_page(id, opts) do |res|
        nash.ids += res.ids if res.ids?
        if res.next_cursor == 0
          delegate.receive_message(:incoming_follower_ids, nash)
        else
          get_followers(id, opts.merge(:cursor => res.next_cursor), nash)
        end
      end
    end
    
    def get_followers_page(id, opts, &blk)
      get("followers/ids/#{id}.json", opts) do |res|
        blk.call(res)
      end
    end
    
    def request(path = "/")
      EventMachine::HttpRequest.new(api_base_url / path)
    end
    
    def get(path, params = {}, &blk)
      http = request(path).get({
        :head => {'Authorization' => @auth_credentials},
        :query => params.stringify_keys
      })
      add_response_callback(http, blk)
      http
    end
    
    def post(path, params = {}, &blk)
      real_params = {}
      params.each_pair { |k,v| real_params[URI.encode(k.to_s)] = URI.encode(v) }
      http = request(path).post({
        :head => {
          'Authorization' => @auth_credentials,
          'Content-Type'  => 'application/x-www-form-urlencoded'
        },
        :body => real_params
      })
      add_response_callback(http, blk)
      http
    end
    
    def add_response_callback(http, blk)
      http.callback do
        if http.response_header.status == 200
          res = parse_response(http)
          if res.nil?
            logger.warn "Got back a blank / errored response."
          elsif successful?(res)
            blk.call(res) unless blk.blank?
          else
            logger.error "Error: #{res.error} (on #{res.request})"
          end
        else
          logger.info "Request returned a non-200 status code, had #{http.response_header.status} instead."
        end
      end
    end
    
    def parse_response(http)
      response = Yajl::Parser.parse(http.response)
      if response.respond_to?(:to_ary)
        response.map { |i| i.to_nash }
      else
        response.to_nash
      end
    rescue Yajl::ParseError => e
      logger.error "Invalid Response: #{http.response} (#{e.message})"
      nil
    end
    
    def successful?(response)
      response.respond_to?(:to_nash) ? !response.to_nash.error? : true
    end
    
    def status_to_args(status_items, type = :tweet)
      results = status_items.to_nash.normalized
      results.type = type
      results
    end
    
    def check_auth!
      if BirdGrinder::Settings["username"].blank? || BirdGrinder::Settings["username"].blank?
        raise BirdGrinder::MissingAuthDetails, "Missing twitter username or password."
      end
    end
    
  end
end