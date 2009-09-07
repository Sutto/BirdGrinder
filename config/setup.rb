BirdGrinder::Loader.before_run do
  DeceptionHandler.register!
end

BirdGrinder::Loader.once_running do
end
