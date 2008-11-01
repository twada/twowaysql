begin
  require 'cucumber'
rescue LoadError
  require 'rubygems'
  require 'cucumber'
end
begin
  require 'cucumber/rake/task'
rescue LoadError
  puts <<-EOS
To use cucumber for testing you must install cucumber gem:
    gem install cucumber
EOS
  exit(0)
end

Cucumber::Rake::Task.new do |t|
end
