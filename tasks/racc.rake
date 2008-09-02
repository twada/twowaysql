namespace :racc do
  desc 'Regenerate parser'
  task :gen do
    `racc -o lib/twowaysql/parser.rb lib/twowaysql/parser.y`
  end

  desc 'Debug parser'
  task :debug do
    `racc -v -o lib/twowaysql/parser.rb -g lib/twowaysql/parser.y`

    $:.unshift(File.dirname(__FILE__) + '/../lib')
    require 'twowaysql'
    template = TwoWaySQL::Template.parse($stdin, :debug => true, :preserve_space => true)
    template.merge({})

    `racc -o lib/twowaysql/parser.rb lib/twowaysql/parser.y`
  end

  desc 'Output tab file'
  task :tab do
    `racc -v -o lib/twowaysql/parser.rb -g lib/twowaysql/parser.y`
  end
end
