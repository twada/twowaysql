require 'forwardable'

module TwoWaySQL

  class Template
    def Template.parse(sql_io, opts={})
      parser = Parser.new(opts)
      root = parser.parse(sql_io)
      Template.new(root)
    end

    def merge(data)
      c = Context.new(data)
      @root.accept(c)
      Result.new(c)
    end
    alias mungle merge

    protected
    def initialize(root)
      @root = root
    end
  end


  class Result
    extend Forwardable
    def initialize(context)
      @context = context
    end
    def_delegators :@context, :sql, :bound_variables
  end

end
