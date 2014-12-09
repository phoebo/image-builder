# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'phoebo/version'

Gem::Specification.new do |spec|
  spec.name          = "phoebo"
  spec.version       = Phoebo::VERSION
  spec.authors       = ["Adam Staněk"]
  spec.email         = ["adam.stanek@v3net.cz"]
  spec.summary       = %q{CI worker for creating Docker images}
  spec.description   = %q{Phoebo creates ready-to-deploy Docker images from project Git repository}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
