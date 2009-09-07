module BirdGrinder
  class Client
    is :loggable, :dispatchable, :cacheable
    
    cattr_accessor :current
    attr_reader :tweeter
    
    def initialize
      logger.debug "Initializing client..."
      @tweeter = BirdGrinder::Tweeter.new(self)
      logger.debug "Notifying handlers of the client"
      handlers.each { |h| h.client = self if h.respond_to?(:client=) }
      self.current = self
    end
    
    def receive_message(type, options = {})
      logger.debug "receiving message: #{type.inspect} - #{options[:id].inspect}"
      dispatch(type.to_sym, options)
      update_stored_id_for(type, options[:id])
    end
    
    def update_all
      fetch :direct_message, :mention
      update_and_schedule_fetch
    end
    
    def tweet(text, opts = {})
      @tweeter.tweet(text, opts)
    end
    
    def dm(user, text, opts = {})
      @tweeter.dm(user, text, opts)
    end
    
    def reply(user, text, opts = {})
      @tweeter.reply(user, text, opts)
    end
    
    # Controller stuff
    
    def self.run
      logger.info "Preparing to start BirdGrinder"
      client = self.new
      EventMachine.run do
        client.run
        BirdGrinder::Loader.invoke_hooks!(:once_running)
      end
    end
    
    def self.stop
      EventMachine.stop_event_loop
    end
    
    protected
    
    def update_and_schedule_fetch
      @last_run_at ||= Time.now
      next_run_time = @last_run_at + BirdGrinder::Settings.check_every
      next_time_spacing = [0, (next_run_time - @last_run_at).to_i].max
      @last_run_at = Time.now
      EventMachine.add_timer(next_time_spacing) { update_all }
    end
    
    def stored_id_for(type)
      cache_get("#{type}-last-id")
    end
    
    def update_stored_id_for(type, id)
      return if id.blank?
      last_id = stored_id_for(type)
      cache_set("#{type}-last-id", id) if last_id.blank? || id > last_id
    end
    
    def fetch(*items)
      items.each do |n|
        fetch_latest :"#{n}s", :"incoming_#{n}"
      end
    end
    
    def fetch_latest(name, type)
      options = {}
      id = stored_id_for(type)
      options[:since_id] = id unless id.blank?
      @tweeter.send(name, options)
    end
    
  end
end