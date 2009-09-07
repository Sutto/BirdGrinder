require 'readline'
require 'irb'
require 'irb/completion'

module BirdGrinder
  class Console
    
    module BaseExtensions
      include BirdGrinder::Loggable
      
      def tweeter
        $tweeter ||= BirdGrinder::Tweeter.new(tweet_drop)
      end
      
      def tweet_drop
        return $tweet_drop unless $tweet_drop.blank?
        tweet_drop_klass = Class.new(Object)
        tweet_drop_klass.class_eval do
          def receive_message(name, options)
            puts ">> #{name.inspect} > #{options.inspect}"
            $tweet_drop_result = [name, options]
          end
        end
        $tweet_drop = tweet_drop_klass.new
      end
      
      def tweet_drop_result
        $tweet_drop_result ||= nil
      end
    
    end
    
    def initialize
      setup_irb
    end
    
    def setup_irb
      # This is a bit hacky, surely there is a better way?
      # e.g. some way to specify which scope irb runs in.
      eval("include BirdGrinder::Console::BaseExtensions", TOPLEVEL_BINDING)
    end
    
    def run
      puts "Loading BirdGrinder Console..."
      # Trick IRB into thinking it has no arguments.
      ARGV.replace []
      IRB.start
    end
    
    def self.run
      self.new.run
    end
    
  end
end