require 'redis'
require 'json' unless Hash.new.respond_to?(:to_json)

class BirdGrinderClient
  class Error < StandardError; end
  
  @@namespace = 'bg:messages'
  
  def self.namespace
    @@namespace
  end
  
  def self.namespace=(value)
    @@namespace = value
  end
  
  def initialize(*args)
    begin
      @redis = Redis.new(*args)
    rescue Errno::ECONNREFUSED
      raise Error, "Unable to connect to Redis"
    end
  end
  
  def dm(user, message)
    send_action 'dm', [user, message]
  end
  
  def tweet(message)
    send_action 'tweet', [message]
  end
  
  def send_action(name, args)
    @redis.push_tail(@@namespace, {'action' => name.to_s, 'arguments' => args}.to_json)
    return true
  rescue Errno::ECONNREFUSED
    raise Error, "Unable to connect to Redis to store message"
  end
  
end
