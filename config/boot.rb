require File.join(File.dirname(__FILE__), '..', 'lib', "bird_grinder")
BirdGrinder::Settings.root = Pathname.new(__FILE__).dirname.join("..").expand_path
