desc 'generate Ditz html report'
task :ditz_report do
  puts 'generate ditz report'
  `ditz -i issues html website/issues`
end
