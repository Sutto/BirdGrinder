BirdGrinder::Loader.before_run do
  StreamDebugger.register!
end

BirdGrinder::Loader.once_running do
  #BirdGrinder::QueueProcessor.start
  #BirdGrinder::Client.current.search "railsrumble"
  #BirdGrinder::Client.current.search "eotw", :repeat => true
  #BirdGrinder::Client.current.streaming.track 'facebook,#facebook,#fb'
end
