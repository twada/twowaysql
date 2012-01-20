# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "twowaysql/version"

Gem::Specification.new do |s|
  s.name        = "twowaysql"
  s.version     = TwoWaySQL::VERSION
  s.authors     = ["Takuto Wada"]
  s.email       = ["takuto.wada@gmail.com"]
  s.homepage    = "https://github.com/twada/twowaysql"
  s.summary     = %q{Template Engine for SQL}
  s.description = %q{Template Engine for SQL}

  s.rubyforge_project = "twowaysql"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "racc"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  # s.add_runtime_dependency "rest-client"
end
