# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ferto/version'

Gem::Specification.new do |spec|
  spec.name          = "ferto"
  spec.version       = Ferto::VERSION
  spec.authors       = ["Aggelos Avgerinos"]
  spec.email         = ["avgerinos@skroutz.gr"]

  spec.summary       = %q{Ruby API client for Downloader}
  spec.description   = %q{Ruby API client for Downloader service}
  spec.homepage      = "https://github.com/skroutz/ferto"
  spec.license       = "GPL-3.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'curb'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "faker"
end
