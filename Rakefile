require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'

require File.join(File.dirname(__FILE__), "lib", "bird_grinder")
CURRENT_VERSION = BirdGrinder.version

spec = Gem::Specification.new do |s|
  s.name        = 'birdgrinder'
  s.email       = 'sutto@sutto.net'
  s.homepage    = 'http://tyrannosexaraptor.com'
  s.authors     = ["Darcy Laycock"]
  s.summary     = "Evented Twitter Library of Doom"
  s.executables = FileList["bin/*"].map { |f| File.basename(f) }
  s.files       = FileList["{bin,lib,templates,test,examples}/**/*"].to_a
  s.platform    = Gem::Platform::RUBY
  s.version     = CURRENT_VERSION
  s.add_dependency "perennial",             ">= 1.2.5"
  s.add_dependency "eventmachine",          ">= 0.12.10"
  s.add_dependency "yajl-ruby",             ">= 0.6.8"
  s.add_dependency "em-http-request",       ">= 0.2.6"
  s.add_dependency "moneta",                ">= 0.6.0"
  # Until we have a version of oauth that incorporates my em-http-request patch,
  # We'll have to use my custom one.
  s.add_dependency "sutto-oauth",           ">= 0.3.6"
  # This should be madsimian-em-redis, but it's broken atm.
  # s.add_dependency "Sutto-em-redis",            ">= 0.1.1"
end

task :default => "test"
task :test => "test:units"

namespace :test do
  desc "Runs the unit tests for birdgrinder"
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
  File.open("#{spec.name}.gemspec", "w+") { |f| f.puts spec.to_ruby }
end

def gemi(name, version)
  command = "gem install #{name} --version '#{version}'"
  puts ">> #{command}"
  system "#{command} 1> /dev/null 2> /dev/null"
end

task :install_dependencies do
  spec.dependencies.each do |dependency|
    gemi dependency.name, dependency.requirement_list.first
  end
end

task :check_dirty do
  if `git status`.include? 'added to commit'
    puts "You have uncommited changes. Please commit them first"
    exit!
  end
end

task :tag => :check_dirty do
  command = "git tag -a v#{CURRENT_VERSION} -m 'Code checkpoint for v#{CURRENT_VERSION}'"
  puts ">> #{command}"
  system command
end

task :commit_gemspec => [:check_dirty, :gemspec] do
  command = "git commit -am 'Generate gemspec for v#{CURRENT_VERSION}'"
  puts ">> #{command}"
  system command
end

task :release => [:commit_gemspec, :tag] do
  puts ">> git push"
  system "git push 1> /dev/null 2> /dev/null"
  system "git push --tags 1> /dev/null 2> /dev/null"
  Rake::Task["gemcutter"].invoke
  puts "New version released."
end

task :gemcutter => [:check_dirty, :gemspec] do
  puts ">> pushing to gemcutter"
  gem_name = "#{spec.name}-#{CURRENT_VERSION}.gem"
  system "gem build #{spec.name}.gemspec && gem push #{gem_name} && rm #{gem_name}"
end
