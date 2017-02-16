# coding: utf-8
lib = File.expand_path('../.', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake_embedded/version'

Gem::Specification.new do |spec|
  spec.name          = "rake_embedded"
  spec.licenses      = ['GPL-3.0']
  spec.version       = RakeEmbedded::VERSION
  spec.authors       = ["Franz Flasch"]
  spec.email         = ["franz.flasch@gmx.at"]
  spec.summary       = "Embedded C buildsystem for microcontrollers" 
  spec.description   = "REM is a Yocto like buildsystem primarily intended for microcontrollers. It is based on ruby rake."
  spec.homepage      = "https://github.com/franzflasch/REM"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  
  spec.bindir        = "."
  spec.executables   = "rem"
  spec.require_paths = ["."]

  spec.add_runtime_dependency "rake", ">= 12.0"

  spec.add_development_dependency "bundler", ">= 1.14"
  spec.add_development_dependency "rake", ">= 12.0"
end
