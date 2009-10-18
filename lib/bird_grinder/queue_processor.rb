require 'em-redis'

module BirdGrinder
  # When running, the queue processor makes it possible to
  # use a redis queue queue up and dispatch tweets and direct
  # messages from external processes. This is useful since
  # it makes it easy to have 1 outgoing source of tweets,
  # triggered from any external application. Included in
  # examples/bird_grinder_client.rb is a simple example
  # client which uses redis to queue tweets and dms.
  class QueueProcessor
    
    cattr_accessor :polling_delay, :namespace, :action_whitelist
    # 10 seconds if queue is empty.
    self.polling_delay    = 10
    self.namespace        = 'bg:messages'
    self.action_whitelist = ["tweet", "dm"]
    
    is :loggable
    
    attr_accessor :tweeter
    
    # Initializes redis and our tweeter.
    def initialize
      @tweeter = Tweeter.new(self)
      @redis   = EM::P::Redis.connect
    end
    
    # Attempts to pop and process an item from the front of the queue.
    # Also, it will queue up the next check - if current item was empty,
    # it will happen after a specified delay otherwise it will check now.
    def check_queue
      logger.debug "Checking Redis for outgoing messages"
      @redis.lpop(@@namespace) do |res|
        if res.blank?
          logger.debug "Empty queue, scheduling check in #{@@polling_delay} seconds"
          schedule_check(@@polling_delay)
        else
          logger.debug "Got item, processing and scheduling next check"
          begin
            process_action Yajl::Parser.parse(res)
          rescue Yajl::ParseError => e
            logger.error "Couldn't parse json: #{e.message}"
          end
          schedule_check
        end
      end
    end
    
    # Check the queue. 
    #
    # @param [Integer, nil] time the specified delay. If nil, it will be done now.
    def schedule_check(time = nil)
      if time == nil
        check_queue
      else
        EventMachine.add_timer(@@polling_delay) { check_queue }
      end
    end
    
    # Processes a given action action - calling handle action
    # if present.
    def process_action(res)
      if res.is_a?(Hash) && res["action"].present?
        handle_action(res["action"], res["arguments"])
      end
    end
    
    # Calls the correct method on the tweeter if present
    # and in the whitelist. logs and caught argument errors.
    def handle_action(action, args)
      args ||= []
      @tweeter.send(action, *[*args]) if @@action_whitelist.include?(action)
    rescue ArgumentError
      logger.warn "Incorrect call for #{action} with arguuments #{args}"
    end
    
    # Starts the queue processor with an initial check.
    # raises an exception if the reactor isn't running.
    def self.start
      raise "EventMachine must be running" unless EM.reactor_running?
      new.check_queue
    end
    
  end
end