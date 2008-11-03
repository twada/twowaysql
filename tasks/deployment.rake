desc 'Release the website and new gem version'
task :deploy => [:check_version, :ditz_release, :website, :release, :tag_release]


desc 'create release tag'
task :tag_release do
  `git tag #{$hoe.version}`
end


namespace :manifest do
  remove_task :refresh
  desc 'Recreate Manifest.txt to include ALL files'
  task :refresh do
    #`rake check_manifest | patch -p0 > Manifest.txt`

    # this task is inspired by http://d.hatena.ne.jp/bellbind/20070605/1180979599
    glob_pattern = File.join("**", "*")
    exclude_patterns = []
    File.open('Manifest.skip') do |file|
      while line = file.gets
        exclude_patterns << Regexp.new(line.chomp)
      end
    end

    files = Dir.glob(glob_pattern).delete_if do |fname|
      File.directory?(fname) or
        exclude_patterns.find do |pattern|
        pattern =~ fname
      end
    end
    manifest = File.new("Manifest.txt", "w")
    manifest.puts files.sort.join("\n")
    manifest.close
  end
end
