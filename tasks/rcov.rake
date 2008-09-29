desc 'generate RCov html report'
task :rcov_report do
  puts 'generate RCov coverage report'
  `rcov -o website/coverage --exclude spec spec/*_spec.rb`
end
