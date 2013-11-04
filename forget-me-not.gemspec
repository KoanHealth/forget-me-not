# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'forget-me-not/version'

Gem::Specification.new do |gem|
  gem.name          = 'forget-me-not'
  gem.version       = ForgetMeNot::VERSION
  gem.authors       = ['Koan Health']
  gem.email         = ['development@koanhealth.com']
  gem.description   = 'Caching and Memoization Mixins'
  gem.summary       = 'Mixins that provide caching and memoization for Ruby classes'
  gem.homepage      = 'https://github.com/KoanHealth/forget-me-not'
  gem.license       = 'MIT'


  gem.required_ruby_version     = ">= 1.9"
  gem.required_rubygems_version = ">= 1.3.6"

  gem.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE.txt README.md Rakefile)
  gem.test_files    = Dir.glob("spec/**/*")
  gem.require_path  = 'lib'

  gem.add_development_dependency 'activesupport', '>= 3.2'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'coveralls'
end
