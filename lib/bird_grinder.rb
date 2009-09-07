lib_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
require 'perennial'

module BirdGrinder
  include Perennial
  
  VERSION = [0, 1, 0, 0]

  def self.version
    VERSION.join(".")
  end
  
  autoload :Tweeter, 'bird_grinder/tweeter'
  
  manifest do |m, l|
    Settings.root = File.dirname(__FILE__)
  end
  
end
