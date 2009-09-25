require 'em-redis'

module BirdGrinder
  class QueueProcessor
    
    cattr_accessor :polling_delay, :namespace, :action_whitelist
    # 10 seconds if queue is empty.
    self.polling_delay    = 10
    self.namespace        = 'bg:messages'
    self.action_whitelist = ["tweet", "dm"]
    
    is :loggable
    
    attr_accessor :tweeter
    
    def initialize
      @tweeter = Tweeter.new(self)
      @redis   = EM::P::Redis.connect
    end
    
    def check_queue
      logger.debug "Checking Redis for outgoing messages"
      @redis.lpop(@@namespace) do |res|
        if res.blank?
          logger.debug "Empty queue, scheduling check in #{@@polling_delay} seconds"
          schedule_check(@@polling_delay)
        else
          logger.debug "Got item, processing and scheduling next check"
          begin
            handle_action Yajl::Parser.parse(res)
          rescue Yajl::ParseError => e
            logger.error "Couldn't parse json: #{e.message}"
          end
          schedule_check
        end
      end
    end
    
    def schedule_check(time = nil)
      if time == nil
        check_queue
      else
        EventMachine.add_timer(@@polling_delay) { check_queue }
      end
    end
    
    def process_action(res)
      if res.is_a?(Hash) && res["action"].present?
        handle_action(res["action"], res["arguments"])
      end
    end
    
    def handle_action(action, args)
      args ||= []
      @tweeter.send(action, *[*args]) if @@action_whitelist.include?(action)
    rescue ArgumentError
      logger.warn "Incorrect call for #{action} with arguuments #{args}"
    end
    
    def self.start
      raise "EventMachine must be running" unless EM.reactor_running?
      new.check_queue
    end
    
  end
end