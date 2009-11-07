require 'set'

module BirdGrinder
  # A simple, method to command mapping for handlers.
  # E.g.
  #
  #   class X < BirdGrinder::CommandHandler
  #     exposes :hello
  #     def hello(name)
  #       reply "Why hello there yourself!"
  #     end
  #   end
  #
  # When registerted, X will look for tweets that are of the form "@bot-name hello"
  # or direct mentions with "hello" at the start (or if command_prefix is set to, 
  # for example, !, "!hello") and reply.
  #
  # Used for implementing the most common cases of bots that respond to commands.
  class CommandHandler < Base
    
    class_inheritable_accessor :exposed_methods, :command_prefix
    self.command_prefix  = ""
    self.exposed_methods = Set.new
    
    class << self
      
      # Marks a set of method names as being available
      # @param [Array<Symbol>] args the method names to expose
      def exposes(*args)
        args.each { |name| exposed_methods << name.to_sym }
      end
      
      # Gets a regexp for easy matching
      # 
      # @return [Regexp] BirdGrinder::CommandHandler.command_prefix in regexp-form
      def prefix_regexp
        /^#{command_prefix}/
      end
      
    end
    
    # Default events
    on_event :incoming_mention,        :check_for_commands
    on_event :incoming_direct_message, :check_for_commands
    
    # Checks in incoming mentions and direct messages for those
    # that correctly match the format. If it's found, it will
    # call the given method with the result of the message,
    # minus the command, as an argument.
    def check_for_commands
      data, command = nil, nil
      if !@last_message_direct
        logger.debug "Checking for command in mention"
        split_message = options.text.split(" ", 3)
        name, command, data = split_message
        if name.downcase != "@#{BirdGrinder::Settings.username}".downcase
          logger.debug "Command is a mention but doesn't start with the username"
          return
        end
      else
        logger.debug "Checking for command in direct message"
        command, data = options.text.split(/\s+/, 2)
      end
      if (command_name = extract_command_name(command)).present?
        logger.info "Processing command '#{command_name}' for #{user}"
        send(command_name, data.to_s) if respond_to?(command_name)
      end
    end
    
    # Given a prefix, e.g. "!awesome", will return the associated
    # method name iff it is exposed.
    #
    # @param [String] the command to check
    # @return [Symbol] the resultant method name or nil if not found.
    def extract_command_name(command)
      re = self.class.prefix_regexp
      if command =~ re
        method_name = command.gsub(re, "").underscore.to_sym
        return method_name if exposed_methods.include?(method_name)
      end
    end
    
  end
end