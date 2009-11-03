# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{birdgrinder}
  s.version = "0.1.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Darcy Laycock"]
  s.date = %q{2009-11-03}
  s.default_executable = %q{birdgrinder}
  s.email = %q{sutto@sutto.net}
  s.executables = ["birdgrinder"]
  s.files = ["bin/birdgrinder", "lib/bird_grinder", "lib/bird_grinder/base.rb", "lib/bird_grinder/cacheable.rb", "lib/bird_grinder/client.rb", "lib/bird_grinder/command_handler.rb", "lib/bird_grinder/console.rb", "lib/bird_grinder/exceptions.rb", "lib/bird_grinder/loader.rb", "lib/bird_grinder/queue_processor.rb", "lib/bird_grinder/stream_handler.rb", "lib/bird_grinder/tweeter", "lib/bird_grinder/tweeter/search.rb", "lib/bird_grinder/tweeter/stream_processor.rb", "lib/bird_grinder/tweeter/streaming.rb", "lib/bird_grinder/tweeter/streaming_request.rb", "lib/bird_grinder/tweeter.rb", "lib/bird_grinder.rb", "lib/birdgrinder.rb", "lib/moneta", "lib/moneta/basic_file.rb", "lib/moneta/redis.rb", "templates/boot.erb", "templates/debug_handler.erb", "templates/hello_world_handler.erb", "templates/rakefile.erb", "templates/settings.yml.erb", "templates/setup.erb", "templates/test_helper.erb", "test/bird_grinder_test.rb", "test/test_helper.rb", "examples/bird_grinder_client.rb"]
  s.homepage = %q{http://tyrannosexaraptor.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Evented Twitter Library of Doom}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<perennial>, [">= 1.0.0.0"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.8"])
      s.add_runtime_dependency(%q<brianmario-yajl-ruby>, [">= 0.6.3"])
      s.add_runtime_dependency(%q<em-http-request>, [">= 0.1.8"])
      s.add_runtime_dependency(%q<Sutto-em-redis>, [">= 0.1.1"])
      s.add_runtime_dependency(%q<wycats-moneta>, [">= 0.6.0"])
    else
      s.add_dependency(%q<perennial>, [">= 1.0.0.0"])
      s.add_dependency(%q<eventmachine>, [">= 0.12.8"])
      s.add_dependency(%q<brianmario-yajl-ruby>, [">= 0.6.3"])
      s.add_dependency(%q<em-http-request>, [">= 0.1.8"])
      s.add_dependency(%q<Sutto-em-redis>, [">= 0.1.1"])
      s.add_dependency(%q<wycats-moneta>, [">= 0.6.0"])
    end
  else
    s.add_dependency(%q<perennial>, [">= 1.0.0.0"])
    s.add_dependency(%q<eventmachine>, [">= 0.12.8"])
    s.add_dependency(%q<brianmario-yajl-ruby>, [">= 0.6.3"])
    s.add_dependency(%q<em-http-request>, [">= 0.1.8"])
    s.add_dependency(%q<Sutto-em-redis>, [">= 0.1.1"])
    s.add_dependency(%q<wycats-moneta>, [">= 0.6.0"])
  end
end
