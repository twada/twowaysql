namespace :racc do
  @grammar = "lib/twowaysql/parser"
  @generate_parser = "racc -o #{@grammar}.rb #{@grammar}.y"
  @debug_parser = "racc -v -o #{@grammar}.rb -g #{@grammar}.y"
  @revert_generated = "git checkout #{@grammar}.rb"
  
  desc 'Regenerate parser'
  task :gen do
    `#{@generate_parser}`
  end

  desc 'Debug parser'
  task :debug do
    `#{@debug_parser}`

    $:.unshift(File.dirname(__FILE__) + '/../lib')
    require 'twowaysql'
    template = TwoWaySQL::Template.parse($stdin, :debug => true)
    template.merge({})

    `#{@revert_generated}`
  end

  desc 'Update tab file'
  task :tab do
    `#{@debug_parser}`
    `#{@revert_generated}`
  end
end
