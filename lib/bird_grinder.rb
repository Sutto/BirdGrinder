lib_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
require 'perennial'

module BirdGrinder
  include Perennial
  
  VERSION = [0, 1, 0, 0]

  def self.version
    VERSION.join(".")
  end
  
  manifest do |m, l|
    Settings.lookup_key_path = []
    Settings.root = __FILE__.to_pathname.dirname.dirname
    l.register_controller :client, 'BirdGrinder::Client'
  end
  
  has_library :cacheable, :tweeter, :client, :base
  
  extends_library :loader
  
end
