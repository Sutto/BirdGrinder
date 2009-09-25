require 'uri'

module BirdGrinder
  # Asynchronous twitter client built on eventmachine
  class Tweeter
    is :loggable, :delegateable
    
    require 'bird_grinder/tweeter/streaming'
    
    VALID_FETCHES = [:direct_messages, :mentions]
    
    cattr_accessor :api_base_url
    self.api_base_url = "http://twetter.sutto.net/"
      
    attr_reader :auth_credentials
        
    def initialize(delegate)
      check_auth!
      @auth_credentials = [BirdGrinder::Settings.username, BirdGrinder::Settings.password]
      delegate_to delegate
    end
    
    def fetch(*fetches)
      options = fetches.extract_options!
      fetches = VALID_FETCHES if fetches == [:all]
      (fetches & VALID_FETCHES).each do |fetch_type|
        send(fetch_type, options.dup)
      end
    end
    
    def follow(user, opts = {})
      user = user.to_s.strip
      logger.debug "Following '#{user}'"
      post("friendships/create.json", opts.merge(:screen_name => user)) do
        delegate.receive_message(:outgoing_follow, :user => user)
      end
    end
    
    def unfollow(user, opts = {})
      user = user.to_s.strip
      logger.debug "Unfollowing '#{user}'"
      post("friendships/destroy.json", opts.merge(:screen_name => user)) do
        delegate.receive_message(:outgoing_unfollow, :user => user)
      end
    end
    
    def tweet(message, opts = {})
      message = message.to_s.strip
      logger.debug "Tweeting #{message}"
      post("statuses/update.json", opts.merge(:status => message)) do |json|
        delegate.receive_message(:outgoing_tweet, status_to_args(json))
      end
    end
    
    def dm(user, text, opts = {})
      text = text.to_s.strip
      user = user.to_s.strip
      logger.debug "DM'ing #{user}: #{text}"
      post("direct_messages/new.json", opts.merge(:user => user, :text => text)) do
        delegate.receive_message(:outgoing_direct_message, :user => user, :text => text)
      end
    end
    
    def streaming
      @streaming ||= Streaming.new(self)
    end
    
    def reply(user, text, opts = {})
      user = user.to_s.strip
      text = text.to_s.strip
      text = "@#{user} #{text}".strip unless text =~ /^\@#{user}\b/
      tweet(text, opts)
    end
    
    def direct_messages(opts = {})
      logger.debug "Fetching direct messages..."
      get("direct_messages.json", opts) do |dms|
        logger.debug "Fetched a total of #{dms.size} direct message(s)"
        dms.each do |dm|
          delegate.receive_message(:incoming_direct_message, status_to_args(dm, :direct_message))
        end
      end
    end
    
    def mentions(opts = {})
      logger.debug "Fetching mentions..."
      get("statuses/mentions.json", opts) do |mentions|
        logger.debug "Fetched a total of #{mentions.size} mention(s)"
        mentions.each do |status|
          delegate.receive_message(:incoming_mention, status_to_args(status, :mention))
        end
      end
    end
        
    protected
    
    def request(path = "/")
      EventMachine::HttpRequest.new(api_base_url / path)
    end
    
    def get(path, params = {}, &blk)
      http = request(path).get({
        :head => {'Authorization' => @auth_credentials},
        :query => params.stringify_keys
      })
      add_response_callback(http, blk)
      return http
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
      return http
    end
    
    def add_response_callback(http, blk)
      http.callback do
        res = parse_response(http)
        if res.nil?
          logger.warn "Got back a blank / errored response."
        elsif successful?(res)
          blk.call(res) unless blk.blank?
        else
          logger.debug "Error: #{res.error} (on #{res.request})"
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
      logger.warn "Invalid Response: #{http.response} (#{e.message})"
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