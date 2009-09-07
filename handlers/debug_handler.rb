# Use this class to debug stuff as you 
# go along - e.g. dump events etc.
class DebugHandler < BirdGrinder::CommandHandler

  def handle(message, options)
    logger.debug "Processing #{message.inspect} with options: #{options.inspect}"
    super
  end
    
end