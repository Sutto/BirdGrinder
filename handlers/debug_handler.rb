# Use this class to debug stuff as you 
# go along - e.g. dump events etc.
class DebugHandler < BirdGrinder::CommandHandler

  exposes :hello
  
  def hello(message)
    logger.info "Got hello from #{user} w/: #{message.inspect}"
    reply "Why hello there"
  end
    
end