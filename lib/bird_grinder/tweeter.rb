require 'json'
require 'uri'

module BirdGrinder
  # Asynchronous twitter client built on eventmachine
  class Tweeter
    is :loggable, :delegateable
    
    require 'bird_grinder/tweeter/stream_processor'
    
    VALID_FETCHES = [:direct_messages, :mentions]
    
    cattr_accessor :api_base_url, :streaming_base_url
    self.api_base_url       = "http://twitter.com/"
    self.streaming_base_url = "http://stream.twitter.com/"
        
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
    
    def reply(user, text, opts = {})
      user = user.to_s.strip
      text = text.to_s.strip
      text = "@#{user} #{text}".strip unless text =~ /^\@#{user}\b/
      tweet(text, opts)
    end
    
    def direct_messages(opts = {})
      logger.debug "Fetching direct messages..."
      get("direct_messages.json", opts) do |json|
        logger.debug "Fetched a total of #{json.size} direct message(s)"
        json.each do |dm|
          delegate.receive_message(:incoming_direct_message, {
            :type       => :direct_message,
            :id         => dm["id"].to_i,
            :full_name  => dm["sender"]["name"],
            :user       => dm["sender"]["screen_name"],
            :text       => dm["text"],
            :created_at => Time.parse(dm["created_at"])
          })
        end
      end
    end
    
    def mentions(opts = {})
      logger.debug "Fetching mentions..."
      get("statuses/mentions.json", opts) do |json|
        logger.debug "Fetched a total of #{json.size} mention(s)"
        json.each do |status|
          delegate.receive_message(:incoming_mention, status_to_args(status, :mention))
        end
      end
    end
  
    def streaming(name, opts = {})
      processor = StreamProcessor.new(self, name.to_sym)
      http_opts = {
        :on_response => processor.method(:receive_chunk),
        :head        => {'Authorization' => @auth_credentials}
      }
      http_opts[:query] = opts unless opts.blank?
      url  = streaming_base_url / "#{name.to_s}.json"
      EventMachine::HttpRequest.new(url).get(http_opts)
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
        json = parse_response(http)
        if json.nil?
          logger.warn "Got back a blank / errored response."
        elsif successful?(json)
          blk.call(json) unless blk.blank?
        else
          logger.debug "Error: #{json["error"]} (on #{json["request"]})"
        end
      end
    end
    
    def parse_response(http)
      JSON.parse(http.response)
    rescue JSON::ParserError
      logger.warn "Invalid Response: #{http.response}"
      return nil
    end
    
    def successful?(json)
      json.is_a?(Hash) ? json["error"].blank? : true
    end
    
    def status_to_args(status_hash, type = :tweet)
      return {} if status_hash.blank?
      {
        :user                  => status_hash["user"]["screen_name"],
        :full_name             => status_hash["user"]["name"],
        :text                  => status_hash["text"],
        :in_reply_to_status_id => status_hash["in_reply_to_status_id"],
        :created_at            => Time.parse(status_hash["created_at"]),
        :type                  => type,
        :id                    => status_hash["id"].to_i
      }
    end
    
    def check_auth!
      if BirdGrinder::Settings["username"].blank? || BirdGrinder::Settings["username"].blank?
        raise BirdGrinder::MissingAuthDetails,
              "Missing twitter username or password."
      end
    end
    
  end
end