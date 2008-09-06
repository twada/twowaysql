module TwoWaySQL

  class Context

    def initialize(data)
      @data = data
      @enabled = true
      @bound_variables = []
      @sql_fragments = []
    end
    attr_reader :bound_variables
    attr_reader :sql_fragments
    attr_reader :data
    
    def sql(separator="")
      @sql_fragments.join(separator)
    end

    def fork_child
      child = Context.new(@data)
      child.disable!
      child
    end

    def join_child(child_ctx)
      @sql_fragments.concat(child_ctx.sql_fragments)
      @bound_variables.concat(child_ctx.bound_variables)
    end

    def add_sql(sql_fragment)
      @sql_fragments << sql_fragment
    end

    def add_value(value)
      @sql_fragments << '?'
      @bound_variables << value
    end

    def add_values(values)
      @sql_fragments << Array.new(values.size, '?').join(', ')
      @bound_variables.concat(values)
    end

    def enabled?
      @enabled
    end

    def enable!
      @enabled = true
    end

    protected
    def disable!
      @enabled = false
    end
  end



  class Node
    protected
    def exec_list(nodes, ctx)
      v = nil
      nodes.each do |i|
        v = i.accept(ctx)
      end
      v
    end

    def do_eval(ctx, exp)
      safe_eval(ctx.data, exp)
    end

    private
    def safe_eval(ctx, exp)
      within_safe_level(4) { eval(exp) }
    end

    def within_safe_level(level)
      result = nil
      Thread.start {
        $SAFE = level
        result = yield
      }.join
      result
    end
  end


  class RootNode < Node
    def initialize(tree)
      @tree = tree
    end
    def accept(ctx)
      exec_list(@tree, ctx)
    end
    def children
      @tree
    end
  end


  class IfNode < Node
    def initialize(cond, tstmt, fstmt)
      @condition = cond
      @tstmt = tstmt
      @fstmt = fstmt
    end
    def accept(ctx)
      if do_eval(ctx, @condition)
        exec_list(@tstmt, ctx)
        ctx.enable!
      elsif @fstmt
        exec_list(@fstmt, ctx)
        ctx.enable!
      end
    end
  end


  class BeginNode < Node
    def initialize(tree)
      @tree = tree
    end
    def accept(ctx)
      child_ctx = ctx.fork_child
      exec_list(@tree, child_ctx)
      if child_ctx.enabled?
        ctx.join_child(child_ctx)
      end
    end
  end


  class SubStatementNode < Node
    def initialize(prefix, tree)
      @prefix = prefix
      @tree = tree
    end
    def accept(ctx)
      ctx.add_sql(@prefix) if ctx.enabled?
      exec_list(@tree, ctx)
    end
    def each
      yield self
    end
  end


  class BindVariableNode < Node
    def initialize(exp)
      @exp = exp
    end
    def accept(ctx)
      ctx.add_value(do_eval(ctx, @exp))
    end
  end


  class QuestionNode < Node
    def initialize(num)
      @num = num
    end
    def accept(ctx)
      ctx.add_value(ctx.data[@num])
    end
  end


  class ParenBindVariableNode < Node
    def initialize(exp)
      @exp = exp
    end
    def accept(ctx)
      result = do_eval(ctx, @exp)
      return if result.nil?
      if result.respond_to?('to_ary')
        bind_values(ctx, result.to_ary)
      else
        ctx.add_value(result)
      end
    end
    def bind_values(ctx, ary)
      return if ary.empty?
      ctx.add_sql("(")
      ctx.add_values(ary)
      ctx.add_sql(")")
    end
  end


  class EmbedVariableNode < Node
    def initialize(exp)
      @exp = exp
    end
    def accept(ctx)
      result = do_eval(ctx, @exp)
      ctx.add_sql(result) unless result.nil?
    end
  end


  class LiteralNode < Node
    def initialize(val)
      @val = val
    end
    def accept(ctx)
      ctx.add_sql(@val)
    end
  end


  class CommentNode < Node
    def initialize(val)
      @val = val
    end
    def accept(ctx)
      # nothing to do
    end
  end


  class EolNode < Node
    def accept(ctx)
      ctx.add_sql("\n")
    end
  end

end
