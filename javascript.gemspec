# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "javascript/version"

Gem::Specification.new do |spec|
  spec.name          = "javascript"
  spec.version       = JavaScript::VERSION
  spec.authors       = ["Godfrey Chan"]
  spec.email         = ["godfreykfc@gmail.com"]
  spec.summary       = "Harness the raw power of your machine with JavaScript"
  spec.description   = "With this gem, Rubyists can finally get really close " \
                       "to the metal by programming in JavaScript syntax right " \
                       "within their Ruby applications."
  spec.homepage      = "https://github.com/chancancode/javascript"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_dependency "binding_of_caller", "~> 0.7.0"

  spec.add_development_dependency "bundler", "~> 1.16"
end
