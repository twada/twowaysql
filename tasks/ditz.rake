namespace :ditz do

  desc 'generate html report'
  task :html do
    `ditz -i issues html website/issues`
  end

end
