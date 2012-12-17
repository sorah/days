# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'days/version'

Gem::Specification.new do |gem|
  gem.name          = "days"
  gem.version       = Days::VERSION
  gem.authors       = ["Shota Fukumori (sora_h)"]
  gem.email         = ["sorah@tubusu.net"]
  gem.description   = %q{Simple blog system built up with Sinatra. Under in development}
  gem.summary       = %q{Simple blog system built up with Sinatra. Under in development}
  gem.homepage      = "https://github.com/sorah/days"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "sinatra"
  gem.add_dependency "sprockets"
  gem.add_dependency "haml"
  gem.add_dependency "scss"
end
