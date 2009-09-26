BirdGrinder::Loader.before_run do
  #DebugHandler.register!
  
  #TwitterWatcher.register!
end

BirdGrinder::Loader.once_running do
  #BirdGrinder::QueueProcessor.start
  #BirdGrinder::Client.current.search "railsrumble"
  #BirdGrinder::Client.current.search "eotw", :repeat => true
end
