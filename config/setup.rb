BirdGrinder::Loader.before_run do
  require 'moneta/basic_file'
  store = Moneta::BasicFile.new(:namespace => 'bird_grinder', :path => File.join(BirdGrinder::Settings.root, "data"))
  BirdGrinder.cache_store = store
  
  DeceptionHandler.register!
end

BirdGrinder::Loader.once_running do
  BirdGrinder::QueueProcessor.start
end
