module BirdGrinder
  # A generic error related to anything broken in BirdGrinder
  class Error              < StandardError; end
  # An error notifying you that username and password are missing from config/settings.yml
  class MissingAuthDetails < Error; end
end