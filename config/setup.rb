require 'moneta/redis'

BirdGrinder::Loader.before_run do
  BirdGrinder.cache_store = Moneta::Memory.new
  DebugHandler.register!
  #DeceptionHandler.register!
end

BirdGrinder::Loader.once_running do
  #BirdGrinder::QueueProcessor.start
end
