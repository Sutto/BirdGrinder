BirdGrinder::Loader.class_eval do
  # Adds a hook so we can trigger events
  # once the client is running.
  define_hook :once_running
end