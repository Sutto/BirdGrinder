require 'ostruct'

module BirdGrinder
  # Glue between BirdGrinder::Tweeter and associated
  # handlers to make it function in an evented fashion.
  #
  # The client basically brings it all together. It acts
  # as a delegate for the tweeter and converts received
  # results into dispatchable form for each handler.
  #
  # @see BirdGrinder::Tweeter
  # @see BirdGrinder::Base
  # @see http://github.com/Sutto/perennial/blob/master/lib/perennial/dispatchable.rb
  class Client
    is :loggable, :dispatchable, :cacheable
    
    cattr_accessor :current
    attr_reader :tweeter
    
    # Initializes this client and creates a new, associated
    # tweeter instance with this client set as the delegate.
    # Also, for all of this clients handlers it will call
    # client= if defined.
    #
    # Lastly, it updates BirdGrinder::Client.current to point
    # to itself.
    #
    # @see BirdGrinder::Tweeter#initialize
    # @see http://github.com/Sutto/perennial/blob/master/lib/perennial/dispatchable.rb
    def initialize
      logger.debug "Initializing client..."
      @tweeter = BirdGrinder::Tweeter.new(self)
      logger.debug "Notifying handlers of the client"
      handlers.each { |h| h.client = self if h.respond_to?(:client=) }
      self.current = self
    end
    
    # Forwards a given message type (with options) to each handler,
    # storing the current id if changed.
    def receive_message(type, options = BirdGrinder::Nash.new)
      logger.debug "receiving message: #{type.inspect} - #{options.id? ? options.id : 'unknown id'}"
      dispatch(type.to_sym, options)
      update_stored_id_for(type, options.id) if options.id?
    end
    
    # Fetches all direct messages and mentions and also schedules
    # the next set of updates.
    #
    # @todo Schedule future fetch only when others are completed.
    def update_all
      fetch :direct_message, :mention
      update_and_schedule_fetch
    end
    
    # Searches for a given query
    #
    # @see BirdGrinder::Tweeter#search
    def search(q, opts = {})
      @tweeter.search(q, opts)
    end
    
    # Tweets some text as the current user
    #
    # @see BirdGrinder::Tweeter#tweet
    def tweet(text, opts = {})
      @tweeter.tweet(text, opts)
    end
    
    # Direct messages a given user with the given text
    #
    # @see BirdGrinder::Tweeter#dm
    def dm(user, text, opts = {})
      @tweeter.dm(user, text, opts)
    end
    
    # Replies to a given user with the given text.
    #
    # @see BirdGrinder::Tweeter#reply
    def reply(user, text, opts = {})
      @tweeter.reply(user, text, opts)
    end
    
    # Starts processing as a new client instance. The main
    # entry point into the programs event loop.
    # Once started, will invoke the once_running hook.    
    def self.run
      logger.info "Preparing to start BirdGrinder"
      client = self.new
      EventMachine.run do
        client.update_all
        BirdGrinder::Loader.invoke_hooks!(:once_running)
      end
    end
    
    # Stops the event loop so the program can be stopped.
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
      Integer(cache_get("#{type}-last-id"))
    rescue ArgumentError
      return -1
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
      options[:since_id] = id unless id.blank? || id.to_i == 0
      @tweeter.send(name, options)
    end
    
  end
end