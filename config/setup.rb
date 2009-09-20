BirdGrinder::Loader.before_run do
  require 'moneta/basic_file'
  store = Moneta::BasicFile.new(:namespace => 'bird_grinder', :path => BirdGrinder::Settings.root.join("data"))
  BirdGrinder.cache_store = store
  
  DeceptionHandler.register!
end

BirdGrinder::Loader.once_running do
end
