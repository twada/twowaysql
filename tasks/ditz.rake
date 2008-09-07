desc 'generate Ditz html report'
task :ditz_report do
  `ditz -i issues html website/issues`
end
