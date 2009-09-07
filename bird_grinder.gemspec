# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{birdgrinder}
  s.version = "0100"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Darcy Laycock"]
  s.date = %q{2009-09-08}
  s.email = %q{sutto@sutto.net}
  s.files = ["bin/birdgrinder", "lib/bird_grinder", "lib/bird_grinder/base.rb", "lib/bird_grinder/cacheable.rb", "lib/bird_grinder/client.rb", "lib/bird_grinder/command_handler.rb", "lib/bird_grinder/console.rb", "lib/bird_grinder/exceptions.rb", "lib/bird_grinder/loader.rb", "lib/bird_grinder/tweeter", "lib/bird_grinder/tweeter/stream_processor.rb", "lib/bird_grinder/tweeter.rb", "lib/bird_grinder.rb", "lib/birdgrinder.rb", "test/bird_grinder_test.rb", "test/test_helper.rb"]
  s.homepage = %q{http://tyrannosexaraptor.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Evented Twitter Library of Doom}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<Sutto-perennial>, [">= 0.2.3.5"])
      s.add_runtime_dependency(%q<eventmachine-eventmachine>, [">= 0.12.9"])
      s.add_runtime_dependency(%q<igrigorik-em-http-request>, [">= 0.1.8"])
    else
      s.add_dependency(%q<Sutto-perennial>, [">= 0.2.3.5"])
      s.add_dependency(%q<eventmachine-eventmachine>, [">= 0.12.9"])
      s.add_dependency(%q<igrigorik-em-http-request>, [">= 0.1.8"])
    end
  else
    s.add_dependency(%q<Sutto-perennial>, [">= 0.2.3.5"])
    s.add_dependency(%q<eventmachine-eventmachine>, [">= 0.12.9"])
    s.add_dependency(%q<igrigorik-em-http-request>, [">= 0.1.8"])
  end
end
