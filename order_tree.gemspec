# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "order_tree/version"

Gem::Specification.new do |s|
  s.name        = "order_tree"
  s.version     = OrderTree::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Prater"]
  s.email       = ["stephenp@agrussell.com"]
  s.homepage    = "http://github.com/stephenprater/order_tree"
  s.summary     = %q{An unbalanced tree / nested hash which remember insertion order}
  s.description = %q{Use OrderTree when you need both insertion order access and nested hash path style access}

  s.rubyforge_project = "order_tree"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency('rspec')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('ruby-prof')
  s.add_development_dependency('ruby-debug19')
end
