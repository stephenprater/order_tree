# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "order_tree/version"

Gem::Specification.new do |s|
  s.name        = "order_tree"
  s.version     = OrderTree::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Prater"]
  s.email       = ["stephenp@agrussell.com"]
  s.homepage    = "agrussell.com"
  s.summary     = %q{TODO: An unbalanced tree / nested hash which remember insertion order}
  s.description = %q{TODO: Use OrderTree when you need both insertion order access and nested hash path style access}

  s.rubyforge_project = "order_tree"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('active_support')

  s.add_development_dependency('rspec')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('ruby-prof')
  s.add_development_dependency('ruby-debug19')
end
