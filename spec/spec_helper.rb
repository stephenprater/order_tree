if ENV["REPORT"] == "1" then
  require 'simplecov'
  require 'ruby-prof'
  require 'ruby-debug'

  SimpleCov.start do
    add_filter "spec.rb"
    coverage_dir "report/coverage"
  end

  RSpec.configure do |config|
    config.before :suite do |example|
      STDOUT << '|'
      RubyProf.start
    end

    config.around :each do |example|
      STDOUT << '.'
      RubyProf.resume do
        example.run
      end
    end
    
    config.after :suite do
      result = RubyProf.stop
      result.eliminate_methods!([/RSpec::Matchers#.*?/])
      printer = RubyProf::MultiPrinter.new(result)
      printer.print(:path => 'report/profile', :profile => "profile")
    end
  end
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
