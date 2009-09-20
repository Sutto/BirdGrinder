require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require File.join(File.dirname(__FILE__), "lib", "bird_grinder")

spec = Gem::Specification.new do |s|
  s.name     = 'birdgrinder'
  s.email    = 'sutto@sutto.net'
  s.homepage = 'http://tyrannosexaraptor.com'
  s.authors  = ["Darcy Laycock"]
  s.version  = BirdGrinder::VERSION
  s.summary  = "Evented Twitter Library of Doom"
  s.files    = FileList["{bin,lib,templates,test}/**/*"].to_a
  s.platform = Gem::Platform::RUBY
  s.add_dependency "Sutto-perennial",           ">= 0.2.3.5"
  s.add_dependency "eventmachine-eventmachine", ">= 0.12.9"
  s.add_dependency "igrigorik-em-http-request", ">= 0.1.8"
  s.add_dependency "madsimian-em-redis",        ">= 0.1.1"
  s.add_dependency "wycats_moneta",             ">= 0.6.0"
end

task :default => "test:units"

namespace :test do
  desc "Runs the unit tests for perennial"
  Rake::TestTask.new("units") do |t|
    t.pattern = 'test/*_test.rb'
    t.libs << 'test'
    t.verbose = true
  end  
end


Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :gemspec do
  File.open("bird_grinder.gemspec", "w+") { |f| f.puts spec.to_ruby }
end

def gemi(name, version)
  command = "gem install #{name} --version '#{version}' --source http://gems.github.com"
  puts ">> #{command}"
  system "#{command} 1> /dev/null 2> /dev/null"
end

task :install_dependencies do
  spec.dependencies.each do |dependency|
    gemi dependency.name, dependency.requirement_list.first
  end
end
