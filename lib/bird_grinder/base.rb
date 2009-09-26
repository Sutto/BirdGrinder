module BirdGrinder
  # A generic base for building handlers. It makes
  # it easy to implement the most common functionality (e.g.,
  # clients, checking origin and the like) without
  # having to reinvent the wheel. Typically used
  # as a handler for Perennial::Dispatchable
  #
  # @see http://github.com/Sutto/perennial/blob/master/lib/perennial/dispatchable.rb
  class Base
    is :loggable
    
    cattr_accessor :handler_mapping
    
    @@handlers = Hash.new do |h,k|
      h[k] = Hash.new { |h2,k2| h2[k2] = [] }
    end
    
    class << self
      
      # Gets event handlers for a given event.
      # @param [Symbol] name the name of the event
      # @return [Array<Proc>] the resultant handlers
      def event_handlers_for(name)
        name = name.to_sym
        handlers = []
        klass = self
        while klass != Object
          handlers += @@handlers[klass][name]
          klass = klass.superclass
        end
        return handlers
      end
      
      # Appends a handler for the given event, either as a
      # block / proc or as a symbol (for a method name) which
      # will be called when the event is triggered.
      #
      # @param [Symbol] name the event name
      # @param [Symbol] method_name if present, will call the given instance method
      # @param [Proc] blk the block to call if method_name isn't given
      def on_event(name, method_name = nil, &blk)
        blk = proc { self.send(method_name) } if method_name.present?
        @@handlers[self][name.to_sym] << blk
      end
      
      # Registers the current handler instance to be used. If not
      # registered, events wont be triggered
      def register!
        BirdGrinder::Client.register_handler(self.new)
      end
      
    end
    
    attr_accessor :options, :client, :user
    
    # Handles a message / event from a dispatcher. This triggers
    # each respective part of the client / lets us act on events.
    #
    # @param [Symbol] message the name of the event, e.g. :incoming_mention
    # @param [Hash, BirdGrinder::Nash] options the options / params for the given event.
    def handle(message, options)
      begin
        setup_details(message, options)
        h = self.class.event_handlers_for(message)
        h.each { |handle| self.instance_eval(&handle) }
      rescue Exception => e
        raise e if e.is_a?(BirdGrinder::HaltHandlerProcessing)
        logger.fatal "Exception processing handlers for #{message}:"
        logger.log_exception(e)
      ensure
        reset_details
      end
    end
    
    # Tweets a given message.
    #
    # @see BirdGrinder::Client#tweet
    # @see BirdGrinder::Tweeter#tweet
    def tweet(message, opts = {})
      @client && @client.tweet(message, opts)
    end
    
    # Direct Messages a specific user if the client exists.
    #
    # @see BirdGrinder::Client#dm
    # @see BirdGrinder::Tweeter#dm
    def dm(user, message, opts = {})
      @client && @client.dm(user, message, opts)
    end
    
    # Replies to the last received message in the correct format.
    # if the last message direct, it will send a dm otherwise it
    # will send a tweet with the correct @-prefix and :in_reply_to_status_id
    # set correctly so twitter users can see what it is replying
    # to.
    #
    # @param [String] message the message to reply with
    # @see http://github.com/Sutto/perennial/blob/master/lib/perennial/dispatchable.rb
    def reply(message)
      message = message.to_s.strip
      return if @user.blank? || @client.blank? || message.blank?
      if @last_message_direct
        @client.dm(@user, message)
      else
        opts = {}
        opts[:in_reply_to_status_id] = @last_message_id.to_s if @last_message_id.present?
        @client.reply(@user, message, opts)
      end
    end
    
    protected
    
    def reset_details
      @direct_last_message = true
      @last_message_origin = nil
      @last_message_id     = nil
      @options             = nil
      @user                = nil
    end
    
    def setup_details(message, options)
      @options               = options.to_nash
      @user                  = options.user.screen_name if options.user? && options.user.screen_name?
      @user                ||= options.sender_screen_name if options.sender_screen_name?
      @last_message_direct   = (message == :incoming_direct_message)
      @last_message_id       = options.id
    end
    
    def halt_handlers!
      raise BirdGrinder::HaltHandlerProcessing
    end
    
  end
end