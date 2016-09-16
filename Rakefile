require "geminabox-release"
GeminaboxRelease.patch(host: "http://gems.example.com/")

task :init do
  Rake::Task["rubocop:install"].execute
end

require "rubocop/rake_task"
RuboCop::RakeTask.new
namespace :rubocop do
  desc "Install Rubocop as pre-commit hook"
  task :install do
    require "rubocop_runner"
    RubocopRunner.install
  end
end

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
