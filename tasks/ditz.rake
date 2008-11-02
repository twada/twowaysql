desc 'generate Ditz html report'
task :ditz_report do
  puts 'generate ditz report'
  `ditz -i issues html website/issues`
end

desc 'ditz release'
task :ditz_release do
  unless ENV['DITZ_REL']
    puts 'Must pass a DITZ_REL=release_name'
    exit
  end

  release = ENV['DITZ_REL']
  puts "ditz release #{release}"
  `ditz -i issues release --no-comment #{release}`

  mv 'History.txt', 'History.txt.tmp'
  puts "generate changelog for #{release}"
  `ditz -i issues changelog #{release} > History.txt`
  `echo '' >> History.txt`
  `cat History.txt.tmp >> History.txt`
  rm 'History.txt.tmp'
end
