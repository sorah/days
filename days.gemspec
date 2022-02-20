# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'days/version'

Gem::Specification.new do |gem|
  gem.name          = "days"
  gem.version       = Days::VERSION
  gem.authors       = ["Sorah Fukumori"]
  gem.email         = ["her@sorah.jp"]
  gem.description   = %q{Simple blog system built up with Sinatra.}
  gem.summary       = %q{Simple blog system built up with Sinatra.}
  gem.homepage      = "https://github.com/sorah/days"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "sinatra", '>= 2.2.0'
  gem.add_dependency "thor"
  gem.add_dependency "rack_csrf"

  gem.add_dependency "settingslogic", '~> 2.0.9'
  gem.add_dependency "psych", '< 4' # safe_load and alias

  gem.add_dependency "sprockets", '~> 4.0.2'
  gem.add_dependency "haml"
  gem.add_dependency "sassc"

  gem.add_dependency "builder", '~> 3.2.4'

  gem.add_dependency "activerecord", "~> 7.0.2"
  gem.add_dependency "otr-activerecord"
  gem.add_dependency "kaminari", "~> 1.2.2"
  gem.add_dependency "kaminari-sinatra", "~> 1.0.1"
  gem.add_dependency "padrino-helpers", '~> 0.15.1'
  gem.add_dependency "stringex", '~> 2.8.5'
  gem.add_dependency "bcrypt", '~> 3.1.16'

  gem.add_dependency "html-pipeline", '>= 2.14.0'
  gem.add_dependency "commonmarker"

  gem.add_development_dependency "sqlite3"

  gem.add_development_dependency "rspec", '~> 3.2.0'
  gem.add_development_dependency "rack-test"
  gem.add_development_dependency "database_rewinder"

  gem.add_dependency "pry"
end
