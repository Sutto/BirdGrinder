module BirdGrinder
  class Client
    include BirdGrinder::Loggable
    include BirdGrinder::Dispatchable
    include BirdGrinder::Cacheable
    
    attr_reader :tweeter
    
    def initialize
      logger.debug "Initializing client..."
      @tweeter = BirdGrinder::Tweeter.new(self)
      logger.debug "Notifying handlers of the client"
      handlers.each { |h| h.client = self if h.respond_to?(:client=) }
    end
    
    
  end
end