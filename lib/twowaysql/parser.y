class TwoWaySQL::Parser

rule

sql            : stmt_list
                {
                  result = RootNode.new( val[0] )
                }

stmt_list      :
                {
                  result = []
                }
               | stmt_list stmt
                {
                  result.push val[1]
                }

stmt           : primary
               | if_stmt
               | begin_stmt

begin_stmt     : BEGIN stmt_list END
                {
                  result = BeginNode.new( val[1] )
                }

if_stmt        : IF sub_stmt else_stmt END
                {
                  result = IfNode.new( val[0], val[1], val[2] )
                }

else_stmt      : ELSE sub_stmt
                {
                  result = val[1]
                }
               |
                {
                  result = nil
                }

sub_stmt       : and_stmt
               | or_stmt
               | stmt_list

and_stmt       : AND stmt_list
                {
                  result = SubStatementNode.new( val[0], val[1] )
                }

or_stmt        : OR stmt_list
                {
                  result = SubStatementNode.new( val[0], val[1] )
                }

primary        : IDENT
                {
                  result = LiteralNode.new( val[0] )
                }
               | STRING_LITERAL
                {
                  result = LiteralNode.new( val[0] )
                }
               | AND
                {
                  result = LiteralNode.new( val[0] )
                }
               | OR
                {
                  result = LiteralNode.new( val[0] )
                }
               | SPACES
                {
                  result = WhiteSpaceNode.new( val[0], @preserve_space )
                }
               | COMMA
                {
                  result = LiteralNode.new( val[0] )
                }
               | LPAREN
                {
                  result = LiteralNode.new( val[0] )
                }
               | RPAREN
                {
                  result = LiteralNode.new( val[0] )
                }
               | QUESTION
                {
                  @num_questions += 1
                  result = QuestionNode.new( @num_questions )
                }
               | ACTUAL_COMMENT
                {
                  result = ActualCommentNode.new( val[0][0] , val[0][1] )
                }
               | bind_var
               | embed_var

bind_var       : BIND_VARIABLE STRING_LITERAL
                {
                  result = BindVariableNode.new( val[0] )
                }
               | BIND_VARIABLE SPACES STRING_LITERAL
                {
                  result = BindVariableNode.new( val[0] )
                }
               | BIND_VARIABLE IDENT
                {
                  result = BindVariableNode.new( val[0] )
                }
               | BIND_VARIABLE SPACES IDENT
                {
                  result = BindVariableNode.new( val[0] )
                }
               | PAREN_BIND_VARIABLE
                {
                  result = ParenBindVariableNode.new( val[0] )
                }

embed_var      : EMBED_VARIABLE IDENT
                {
                  result = EmbedVariableNode.new( val[0] )
                }
               | EMBED_VARIABLE SPACES IDENT
                {
                  result = EmbedVariableNode.new( val[0] )
                }

end


---- inner

require 'strscan'

def initialize(opts={})
  opts = {
    :debug => false,
    :preserve_space => true,
    :preserve_comment => false
  }.merge(opts)
  @yydebug = opts[:debug]
  @preserve_space = opts[:preserve_space]
  @preserve_comment = opts[:preserve_comment]
  @num_questions = 0
end


PAREN_EXAMPLE                = '\([^\)]+\)'
BEGIN_BIND_VARIABLE          = '(\/|\#)\*([^\*]+)\*\1'
BIND_VARIABLE_PATTERN        = /\A#{BEGIN_BIND_VARIABLE}\s*/
PAREN_BIND_VARIABLE_PATTERN  = /\A#{BEGIN_BIND_VARIABLE}\s*#{PAREN_EXAMPLE}/
EMBED_VARIABLE_PATTERN       = /\A(\/|\#)\*\$([^\*]+)\*\1\s*/

CONDITIONAL_PATTERN     = /\A(\/|\#)\*(IF)\s+([^\*]+)\s*\*\1/
BEGIN_END_PATTERN       = /\A(\/|\#)\*(BEGIN|END)\s*\*\1/
STRING_LITERAL_PATTERN  = /\A(\'(?:[^\']+|\'\')*\')/   ## quoted string
SPLIT_TOKEN_PATTERN     = /\A(\S+?)(?=\s*(?:(?:\/|\#)\*|-{2,}|\(|\)|\,))/  ## stop on delimiters --,/*,#*,',',(,)
LITERAL_PATTERN         = /\A([^;\s]+)/
SPACES_PATTERN          = /\A(\s+)/
QUESTION_PATTERN        = /\A\?/
COMMA_PATTERN           = /\A\,/
LPAREN_PATTERN          = /\A\(/
RPAREN_PATTERN          = /\A\)/
ACTUAL_COMMENT_PATTERN          = /\A(\/|\#)\*(\s{1,}(?:.*?))\*\1/m  ## start with spaces
SEMICOLON_AT_INPUT_END_PATTERN  = /\A\;\s*\Z/
UNMATCHED_COMMENT_START_PATTERN = /\A(?:(?:\/|\#)\*)/

#TODO: remove trailing spaces for S2Dao compatibility, but this spec sometimes causes SQL bugs...
ELSE_PATTERN            = /\A\-{2,}\s*ELSE\s*/
AND_PATTERN             = /\A(\ *AND)\b/i
OR_PATTERN              = /\A(\ *OR)\b/i


def parse( io )
  @q = []
  io.each_line(nil) do |whole|
    @s = StringScanner.new(whole)
  end
  scan_str
  @q.push [ false, nil ]
    
  ## cal racc's private parse method
  do_parse
end

## called by racc
def next_token
  @q.shift
end


def scan_str
  until @s.eos? do
    case
    when @s.scan(AND_PATTERN)
      @q.push [ :AND, @s[1] ]
    when @s.scan(OR_PATTERN)
      @q.push [ :OR, @s[1] ]
    when @s.scan(SPACES_PATTERN)
      @q.push [ :SPACES, @s[1] ]
    when @s.scan(QUESTION_PATTERN)
      @q.push [ :QUESTION, nil ]
    when @s.scan(COMMA_PATTERN)
      @q.push [ :COMMA, ',' ]
    when @s.scan(LPAREN_PATTERN)
      @q.push [ :LPAREN, '(' ]
    when @s.scan(RPAREN_PATTERN)
      @q.push [ :RPAREN, ')' ]
    when @s.scan(ELSE_PATTERN)
      @q.push [ :ELSE, nil ]
    when @s.scan(ACTUAL_COMMENT_PATTERN)
      @q.push [ :ACTUAL_COMMENT, [@s[1], @s[2]] ] if @preserve_comment
    when @s.scan(BEGIN_END_PATTERN)
      @q.push [ @s[2].intern, nil ]
    when @s.scan(CONDITIONAL_PATTERN)
      @q.push [ @s[2].intern, @s[3] ]
    when @s.scan(EMBED_VARIABLE_PATTERN)
      @q.push [ :EMBED_VARIABLE, @s[2] ]
    when @s.scan(PAREN_BIND_VARIABLE_PATTERN)
      @q.push [ :PAREN_BIND_VARIABLE, @s[2] ]
    when @s.scan(BIND_VARIABLE_PATTERN)
      @q.push [ :BIND_VARIABLE, @s[2] ]
    when @s.scan(STRING_LITERAL_PATTERN)
      @q.push [ :STRING_LITERAL, @s[1] ]
    when @s.scan(SPLIT_TOKEN_PATTERN)
      @q.push [ :IDENT, @s[1] ]
    when @s.scan(UNMATCHED_COMMENT_START_PATTERN)   ## unmatched comment start, '/*','#*'
      raise Racc::ParseError, "## unmatched comment. line:[#{line_no}], rest:[#{@s.rest}]"
    when @s.scan(LITERAL_PATTERN)   ## other string token
      @q.push [ :IDENT, @s[1] ]
    when @s.scan(SEMICOLON_AT_INPUT_END_PATTERN)
      #drop semicolon at input end
    else
      raise Racc::ParseError, "## cannot parse. line:[#{line_no}], rest:[#{@s.rest}]"
    end
  end
end


def line_no
  lines = 0
  scanned = @s.string[0..(@s.pos)]
  scanned.each_line { lines += 1 }
  lines
end
