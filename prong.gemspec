# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prong/version'

Gem::Specification.new do |spec|
  spec.name          = "prong"
  spec.version       = Prong::VERSION
  spec.authors       = ["Ehsan Yousefi"]
  spec.email         = ["ehsan.yousefi@live.com"]

  spec.summary       = %q{Activesupport-like callbacks but upto %20 faster.}
  spec.description   = %q{Prong is almost behave like ActiveSupport::Callbakcs in most of the cases. It's let you define hooks, add callbacks to them, and conditionally run them whenever you want. Prong is not just another one, It's faster! It's independent! Also there is some differences. }
  spec.homepage      = "https://github.com/EhsanYousefi/Prong"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
