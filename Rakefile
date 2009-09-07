require 'rake'
require 'rake/testtask'

task :default => "test:units"

namespace :test do
  
  desc "Runs the unit tests for perennial"
  Rake::TestTask.new("units") do |t|
    t.pattern = 'test/*_test.rb'
    t.libs << 'test'
    t.verbose = true
  end
  
end

task :gemspec do
  require 'rubygems'
  require File.join(File.dirname(__FILE__), "lib", "bird_grinder")
  spec = Gem::Specification.new do |s|
    s.name     = 'birdgrinder'
    s.email    = 'sutto@sutto.net'
    s.homepage = 'http://tyrannosexaraptor.com'
    s.authors  = ["Darcy Laycock"]
    s.version  = BirdGrinder::VERSION
    s.summary  = "Evented Twitter Library of Doom"
    s.files    = FileList["{bin,vendor,lib,test}/**/*"].to_a
    s.platform = Gem::Platform::RUBY
    s.add_dependency "Sutto-perennial", ">= 0.2.3.4"
  end
  File.open("bird_grinder.gemspec", "w+") { |f| f.puts spec.to_ruby }
end
