require 'readline'
require 'irb'
require 'irb/completion'

module BirdGrinder
  # A simple controller for bringing up an IRB instance with the birdgrinder
  # environment pre-loaded.
  class Console
    
    # Define code here that you want available at the IRB
    # prompt automatically.
    module BaseExtensions
      include BirdGrinder::Loggable    
    end
    
    def initialize
      setup_irb
    end
    
    # Include the base extensions in our top level binding
    # so they can be accessed at the prompt.
    def setup_irb
      # This is a bit hacky, surely there is a better way?
      # e.g. some way to specify which scope irb runs in.
      eval("include BirdGrinder::Console::BaseExtensions", TOPLEVEL_BINDING)
    end
    
    # Actually starts IRB
    def run
      puts "Loading BirdGrinder Console..."
      # Trick IRB into thinking it has no arguments.
      ARGV.replace []
      IRB.start
    end
    
    # Starts up a new IRB instance with access to birdgrinder features.
    def self.run
      self.new.run
    end
    
  end
end