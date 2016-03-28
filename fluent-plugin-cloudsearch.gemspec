# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-cloudsearch"
  spec.version       = "0.1.1"
  spec.authors       = ["Kensaku Araga"]
  spec.email         = ["ken39arg@gmail.com"]

  spec.summary       = %q{Amazon CloudSearch output plugin for Fluent event collector.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/ken39arg/fluent-plugin-cloudsearch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd"
  spec.add_dependency "aws-sdk", "~> 2"
  spec.add_dependency "json"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "test-unit-rr"

end
