require "bundler/gem_tasks"
require "rake/testtask"

desc 'Run tests'
test_task = Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task default: :test
