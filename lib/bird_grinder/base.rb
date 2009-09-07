module BirdGrinder
  class Base
    is :loggable
    
    cattr_accessor :handler_mapping
    
    @@handlers = Hash.new do |h,k|
      h[k] = Hash.new { |h2,k2| h2[k2] = [] }
    end
    
    class << self
      
      def event_handlers_for(name, direct = true)
        name = name.to_sym
        handlers = []
        klass = self
        while klass != Object
          handlers += @@handlers[klass][name]
          klass = klass.superclass
        end
        return handlers
      end
      
      def on_event(name, method_name = nil, &blk)
        blk = proc { self.send(method_name) } if method_name.present?
        @@handlers[self][name.to_sym] << blk
      end
      
      def register!
        BirdGrinder::Client.register_handler(self.new)
      end
      
    end
    
    attr_accessor :options, :client
    
    def handle(message, options)
      begin
        setup_details(message, options)
        h = self.class.event_handlers_for(message)
        h.each { |handle| self.instance_eval(&handle) }
      rescue Exception => e
        logger.fatal "Exception processing handlers for #{message}:"
        logger.log_exception(e)
      ensure
        reset_details
      end
    end
    
    def tweet(message, opts = {})
      @client && @client.tweet(message, opts)
    end
    
    def dm(user, message, opts = {})
      @client && @client.dm(user, message, opts)
    end
    
    def reply(message)
      message = message.to_s.strip
      return if @user.blank? || @client.blank? || message.blank?
      if @last_message_direct
        @client.dm(@user, message)
      else
        opts = {}
        opts[:in_reply_to_id] = @last_message_id if @last_message_id.present?
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
      @options             = options.is_a?(OpenStruct) ? options : OpenStruct.new(options)
      @user                = options[:user] if options.has_key?(:user)
      @last_message_direct = (message == :incoming_direct_message)
      @last_message_id     = options[:id]
    end
    
  end
end