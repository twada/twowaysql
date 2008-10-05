require File.dirname(__FILE__) + '/spec_helper.rb'


describe "Ruby Regex" do

  describe "comment node match" do
    before do
      @re = /\/\*.*?\*\//m
    end

    it "comment node" do
      str = "int a = 1; /* this is a comment.*/"
      str.scan(@re).should == ["/* this is a comment.*/"]
    end

    it "multi-line commnet" do
      str = <<-EOS
Hey,
/*
this is commented
*/
non-comment
EOS
      str.scan(@re).should == ["/*\nthis is commented\n*/"]
    end
  end


  describe "string expression" do
    before do
      @str_re = /"([^"\\]*(?:\\.[^"\\]*)*)"/
    end
    it "normal string" do
      (@str_re =~ 'he said "foo bar"').should_not be_nil
      $1.should == 'foo bar'
    end
  end



  describe "non-whitespace delimiters" do
    before do
      @str_re = /\A(\S+?)(?=\s*(?:(?:\/|\#)\*|-{2,}|\(|\)|\,))/
    end

    describe "-- comment start" do
      it '' do
        (@str_re =~ 'foo-bar--ELSE').should_not be_nil
        $1.should == 'foo-bar'
        $'.should == '--ELSE'
      end
      it 'foo-bar--ELSE' do
        (@str_re =~ 'foo-bar--ELSE').should_not be_nil
        $1.should == 'foo-bar'
        $'.should == '--ELSE'
      end
      it 'foo-bar --ELSE' do
        (@str_re =~ 'foo-bar --ELSE').should_not be_nil
        $1.should == 'foo-bar'
        $'.should == ' --ELSE'
      end
      it 'foobar--ELSE' do
        (@str_re =~ 'foobar--ELSE').should_not be_nil
        $1.should == 'foobar'
        $'.should == '--ELSE'
      end
      it 'foo-bar---ELSE' do
        (@str_re =~ 'foo-bar---ELSE').should_not be_nil
        $1.should == 'foo-bar'
        $'.should == '---ELSE'
      end
      it "it's OK to not to match 'foobar'" do
        (@str_re =~ 'foobar').should be_nil
        $1.should be_nil
        $&.should be_nil
        $'.should be_nil
      end
    end

    describe "/* comment start" do
      it "match before spaces" do
        (@str_re =~ 'foo/bar /* hoge */').should_not be_nil
        $1.should == 'foo/bar'
        $'.should == ' /* hoge */'
      end
      it '' do
        (@str_re =~ 'foo/bar/* hoge */').should_not be_nil
        $1.should == 'foo/bar'
        $'.should == '/* hoge */'
      end
      it '' do
        (@str_re =~ 'foo/bar/* hoge */').should_not be_nil
        $1.should == 'foo/bar'
        $'.should == '/* hoge */'
      end
      it '' do
        (@str_re =~ 'foobar/* hoge */').should_not be_nil
        $1.should == 'foobar'
        $'.should == '/* hoge */'
      end
    end

    describe "#* comment start" do
      it "match before spaces" do
        (@str_re =~ 'foo#bar #* hoge *#').should_not be_nil
        $1.should == 'foo#bar'
        $'.should == ' #* hoge *#'
      end
      it '' do
        (@str_re =~ 'foo#bar#* hoge *#').should_not be_nil
        $1.should == 'foo#bar'
        $'.should == '#* hoge *#'
      end
      it '' do
        (@str_re =~ 'foo#bar#* hoge *#').should_not be_nil
        $1.should == 'foo#bar'
        $'.should == '#* hoge *#'
      end
      it '' do
        (@str_re =~ 'foobar#* hoge *#').should_not be_nil
        $1.should == 'foobar'
        $'.should == '#* hoge *#'
      end
    end

    describe "comma" do
      it '' do
        (@str_re =~ 'foo,bar').should_not be_nil
        $1.should == 'foo'
        $'.should == ',bar'
      end
      it '' do
        (@str_re =~ 'foo , bar').should_not be_nil
        $1.should == 'foo'
        $'.should == ' , bar'
      end
    end

    describe "left paren" do
      it '' do
        (@str_re =~ 'foo(bar').should_not be_nil
        $1.should == 'foo'
        $'.should == '(bar'
      end
      it '' do
        (@str_re =~ 'foo ( bar').should_not be_nil
        $1.should == 'foo'
        $'.should == ' ( bar'
      end
    end

    describe "right paren" do
      it '' do
        (@str_re =~ 'foo)bar').should_not be_nil
        $1.should == 'foo'
        $'.should == ')bar'
      end
      it '' do
        (@str_re =~ 'foo ) bar').should_not be_nil
        $1.should == 'foo'
        $'.should == ' ) bar'
      end
    end

  end



  describe "double-single-quote escape" do
    before do
      @str_re = /(\'(?:[^\']+|\'\')*\')/
    end
    it '' do
      (@str_re =~ "he said 'foo bar' then 'baz'").should_not be_nil
      $1.should == "'foo bar'"
    end
    it '' do
      (@str_re =~ "he said 'Let''s go' then went out").should_not be_nil
      $1.should == "'Let''s go'"
    end
    it '' do
      (@str_re =~ "he said 'foo bar'then went out").should_not be_nil
      $1.should == "'foo bar'"
    end
    it '' do
      sql = "SELECT * FROM emp/*BEGIN*/ WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'/*END*//*IF ctx['deptno']*/ AND deptno = /*ctx[:deptno]*/20/*END*//*END*/"
      (@str_re =~ sql).should_not be_nil
      $1.should == "'CLERK'"
    end
    
  end



  describe "comment start-end pair" do
    before do
      @str_re = /\A(\/|\#)\*([^\*]+)\*\1/
    end

    describe "matched pair" do
      it '' do
        (@str_re =~ '/*ctx[:job]*/').should_not be_nil
        $1.should == '/'
        $2.should == 'ctx[:job]'
        $'.should == ''
      end

      it '' do
        (@str_re =~ '#*ctx[:job]*#').should_not be_nil
        $1.should == '#'
        $2.should == 'ctx[:job]'
        $'.should == ''
      end
    end

    describe "unmatched pair" do
      it '' do
        (@str_re =~ '/*ctx[:job]*#').should be_nil
        $1.should be_nil
        $2.should be_nil
        $'.should be_nil
      end
      
      it '' do
        (@str_re =~ '/*ctx[:job]*#').should be_nil
        $1.should be_nil
        $2.should be_nil
        $'.should be_nil
      end
    end

  end

end
