# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conn/version'

Gem::Specification.new do |spec|
  spec.name          = "conn"
  spec.version       = Conn::VERSION
  spec.authors       = ["Uchio KONDO"]
  spec.email         = ["udzura@udzura.jp"]

  spec.summary       = %q{Super simple server connector}
  spec.description   = %q{Super simple server connector}
  spec.homepage      = "https://github.com/udzura/conn"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "net-ssh"
  spec.add_dependency "colored"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
