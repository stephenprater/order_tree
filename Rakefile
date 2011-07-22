require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rspec_opts = "-d"
end

RSpec::Core::RakeTask.new(:spec_with_report) do |spec|
  spec.fail_on_error = false
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rspec_opts = "--format html --out report/test_report.html"
end

task :report do
  Dir.mkdir "report" unless File.exists? "report"
  Dir.mkdir "report/profile" unless File.exists? "report/profile"
  File.open "report/index.html","w" do |f|
    f.write <<-HTML
      <html>
        <body>
          <h1> Status Report </h1>
          <a href="coverage/index.html"> Coverage </a>
          <a href="profile/profile.html"> Speed Profile </a>
          <a href="test_report.html"> Test Report </a>
        </body>
      </html>
    HTML
  end
  ENV["REPORT"] = "1" 
  Rake::Task[:spec_with_report].invoke
  ENV["REPORT"] = ""
end 

task :default => :spec

