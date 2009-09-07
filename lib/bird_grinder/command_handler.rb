require 'set'

module BirdGrinder
  class CommandHandler < Base
    
    class_inheritable_accessor :exposed_methods, :command_prefix
    self.command_prefix  = ""
    self.exposed_methods = Set.new
    
    class << self
      
      def exposes(*args)
        args.each { |name| exposed_methods << name.to_sym }
      end
      
      def prefix_regexp
        /^#{command_prefix}/
      end
      
    end
    
    on_event :incoming_mention,        :check_for_commands
    on_event :incoming_direct_message, :check_for_commands
    
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
        command, data = options.text.split(" ", 2)
      end
      if (command_name = extract_command_name(command)).present?
        logger.info "Processing command '#{command_name}' for #{user}"
        send(command_name, data) if respond_to?(command_name)
      end
    end
    
    def extract_command_name(command)
      re = self.class.prefix_regexp
      if command =~ re
        method_name = command.gsub(re, "").underscore.to_sym
        return method_name if exposed_methods.include?(method_name)
      end
    end
    
  end
end