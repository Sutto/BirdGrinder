require 'moneta/redis'

BirdGrinder::Loader.before_run do
  BirdGrinder.cache_store = Moneta::Redis.new
  DeceptionHandler.register!
end

BirdGrinder::Loader.once_running do
  BirdGrinder::QueueProcessor.start
end
