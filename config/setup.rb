BirdGrinder::Loader.before_run do
  DebugHandler.register!
end

BirdGrinder::Loader.once_running do
end
