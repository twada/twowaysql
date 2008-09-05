begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'twowaysql'



## workaround for RSpec with ruby 1.9 cause 'wrong argument type Proc (expected Binding) (TypeError)'
#
# before:
#   params[:spec_path] = eval("caller(0)[1]", example_group_block) unless params[:spec_path]
# after:
#   params[:spec_path] = eval("caller(0)[1]", example_group_block.binding) unless params[:spec_path]
#
module Spec::Example::ExampleGroupMethods

      def describe(*args, &example_group_block)
        args << {} unless Hash === args.last
        if example_group_block
          params = args.last
          params[:spec_path] = eval("caller(0)[1]", example_group_block.binding) unless params[:spec_path]
          if params[:shared]
            SharedExampleGroup.new(*args, &example_group_block)
          else
            self.subclass("Subclass") do
              describe(*args)
              module_eval(&example_group_block)
            end
          end
        else
          set_description(*args)
          before_eval
          self
        end
      end

end
