# Use this class to debug stuff as you 
# go along - e.g. dump events etc.
class DebugHandler < BirdGrinder::CommandHandler
  
  def handle(name, opts)
    if name == :incoming_follower_ids
      logger.warn "Processing ids for #{opts.user_id} - has #{opts.ids.size} followers"
    end
  end
  
end