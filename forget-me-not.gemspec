# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'forget-me-not/version'

Gem::Specification.new do |gem|
  gem.name          = "forget-me-not"
  gem.version       = ForgetMeNot::VERSION
  gem.authors       = ["Koan Health"]
  gem.email         = ["development@koanhealth.com"]
  gem.description   = %q{Caching and Memoization Mixins}
  gem.summary       = %q{Mixins that provide caching and memoization for Ruby classes}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'activesupport', '>= 3.2'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'coveralls'

end
