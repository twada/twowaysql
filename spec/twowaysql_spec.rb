require File.dirname(__FILE__) + '/spec_helper.rb'


describe TwoWaySQL::Template do

  before do
    @ctx = {}
  end



  describe "when parse SQL without comment nodes, e.g. 'SELECT * FROM emp'" do
    before do
      sql = "SELECT * FROM emp"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      @result = @template.merge(@ctx)
    end

    it "should not change original sql" do
      @result.sql.should == "SELECT * FROM emp"
    end

    it "should have empty bound valiables" do
      @result.bound_variables.should be_empty
    end
  end



  describe "when parsed from 'SELECT * FROM emp WHERE job = /*ctx[:job]*/'CLERK' AND deptno = /*ctx[:deptno]*/20'" do
    before do
      sql = "SELECT * FROM emp WHERE job = /*ctx[:job]*/'CLERK' AND deptno = /*ctx[:deptno]*/20"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "pass Context with Symbol keys like ctx[:job] = 'HOGE' and ctx[:deptno] = 30" do
      before do
        @ctx[:job] = "HOGE"
        @ctx[:deptno] = 30
        @result = @template.merge(@ctx)
      end

      it "should parse '/*' as comment start and '*/' as comment end, then replace them with question mark. so SQL will 'SELECT * FROM emp WHERE job = ? AND deptno = ?'" do
        @result.sql.should == "SELECT * FROM emp WHERE job = ? AND deptno = ?"
      end

      it "should have two bound variables in Array ['HOGE', 30]" do
        @result.bound_variables.should == ["HOGE", 30]
      end
    end
  end



  describe "when parsed from 'SELECT * FROM emp WHERE job = /*ctx['job']*/'CLERK' AND deptno = /*ctx['deptno']*/20'" do
    before do
      sql = "SELECT * FROM emp WHERE job = /*ctx['job']*/'CLERK' AND deptno = /*ctx['deptno']*/20"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "pass Context with String keys like ctx['job'] = 'HOGE' and ctx['deptno'] = 30" do
      before do
        @ctx['job'] = "HOGE"
        @ctx['deptno'] = 30
        @result = @template.merge(@ctx)
      end

      it "should parse '/*' as comment start and '*/' as comment end, then replace them with question mark. so SQL will 'SELECT * FROM emp WHERE job = ? AND deptno = ?'" do
        @result.sql.should == "SELECT * FROM emp WHERE job = ? AND deptno = ?"
      end

      it "should have two bound variables in Array ['HOGE', 30]" do
        @result.bound_variables.should == ["HOGE", 30]
      end
    end
  end



  describe "when parsed from 'SELECT * FROM emp WHERE job = #*ctx[:job]*#'CLERK' AND deptno = #*ctx[:deptno]*#20'" do
    before do
      sql = "SELECT * FROM emp WHERE job = #*ctx[:job]*#'CLERK' AND deptno = #*ctx[:deptno]*#20"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      
      @ctx[:job] = "HOGE"
      @ctx[:deptno] = 30
      @result = @template.merge(@ctx)
    end
    
    it "should parse '#*' as comment start and '*#' as comment end, then replace them with question mark. so SQL will 'SELECT * FROM emp WHERE job = ? AND deptno = ?'" do
      @result.sql.should == 'SELECT * FROM emp WHERE job = ? AND deptno = ?'
    end

    it "should have two variables" do
      @result.bound_variables.size.should == 2
    end

    it "should have two bound variables in Array" do
      @result.bound_variables.should == ["HOGE", 30]
    end
  end



  describe "when parsed from SQL file with one or more white speces in comment, like 'SELECT * FROM emp WHERE job = /* ctx[:job]*/'CLERK''" do
    before do
      sql = "SELECT * FROM emp WHERE job = /* ctx[:job]*/'CLERK'"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)

      @ctx[:job] = "HOGE"
      @result = @template.merge(@ctx)
    end
    
    it "should treat comment node which starts with one or more speces like /* ctx[:job]*/'CLERK' as real comment node, therefore it does *NOT* replace comment node with question mark. so SQL will 'SELECT * FROM emp WHERE job = 'CLERK''" do
      @result.sql.should == "SELECT * FROM emp WHERE job = 'CLERK'"
    end

    it "should have no variable nodes, so return empty Array as bound variables" do
      @result.bound_variables.should be_empty
    end
  end



  describe "when parsed from 'SELECT * FROM emp WHERE empno = /*ctx[:empno]*/1 AND 1 = 1'" do
    before do
      sql = "SELECT * FROM emp WHERE empno = /*ctx[:empno]*/1 AND 1 = 1"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      
      @ctx[:empno] = 7788
      @result = @template.merge(@ctx)
    end

    it "parsed SQL should 'SELECT * FROM emp WHERE empno = ? AND 1 = 1'" do
      @result.sql.should == 'SELECT * FROM emp WHERE empno = ? AND 1 = 1'
    end

    it "should have bound variables in Array [7788]" do
      @result.bound_variables.should == [7788]
    end
  end



  describe "when parsed from 'SELECT * FROM emp/*IF ctx[:job] */ WHERE job = /*ctx[:job]*/'CLERK'/*END*/'" do
    before do
      sql = "SELECT * FROM emp/*IF ctx[:job] */ WHERE job = /*ctx[:job]*/'CLERK'/*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :job param exists" do
      before do
        @ctx[:job] = "HOGE"
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE job = ?'" do
        @result.sql.should == 'SELECT * FROM emp WHERE job = ?'
      end
      it "should have bound variables in Array ['HOGE']" do
        @result.bound_variables.should == ['HOGE']
      end
    end

    describe "and when :job param does not exist" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp'" do
        @result.sql.should == 'SELECT * FROM emp'
      end
      it "bound variables should be empty" do
        @result.bound_variables.should be_empty
      end
    end
  end



  describe "when parsed from SQL with 'nested if' like '/*IF ctx[:aaa]*/aaa/*IF ctx[:bbb]*/bbb/*END*//*END*/'" do
    before do
      sql = "/*IF ctx[:aaa]*/aaa/*IF ctx[:bbb]*/bbb/*END*//*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when inner is true but outer is false" do
      before do
        @ctx[:bbb] = "hoge"
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should be empty'" do
        @result.sql.should be_empty
      end
      it "bound variables is empty too" do
        @result.bound_variables.should be_empty
      end
    end

    describe "and when outer is true and inner is false" do
      before do
        @ctx[:aaa] = "hoge"
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should be 'aaa'" do
        @result.sql.should == 'aaa'
      end
      it "should have no bound variables because there is no assignments" do
        @result.bound_variables.should be_empty
      end
    end

    describe "and when both outer and inner is true" do
      before do
        @ctx[:aaa] = "hoge"
        @ctx[:bbb] = "foo"
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should be 'aaabbb'" do
        @result.sql.should == 'aaabbb'
      end
      it "should have no bound variables because there is no assignments" do
        @result.bound_variables.should be_empty
      end
    end

  end



  describe "when parsed from 'SELECT * FROM emp WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'-- ELSE job is null/*END*/'" do
    before do
      sql = "SELECT * FROM emp WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'-- ELSE job is null/*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :job param exists" do
      before do
        @ctx[:job] = "HOGE"
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE job = ?'" do
        @result.sql.should == 'SELECT * FROM emp WHERE job = ?'
      end
      it "should have bound variables in Array ['HOGE']" do
        @result.bound_variables.should == ['HOGE']
      end
    end

    describe "and when :job param does not exist" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE job is null'" do
        @result.sql.should == 'SELECT * FROM emp WHERE job is null'
      end
      it "bound variables should be empty" do
        @result.bound_variables.should be_empty
      end
    end
  end



  describe "when parsed from '/*IF false*/aaa--ELSE bbb = /*ctx[:bbb]*/123/*END*/'" do
    before do
      sql = "/*IF false*/aaa--ELSE bbb = /*ctx[:bbb]*/123/*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :bbb param exists" do
      before do
        @ctx[:bbb] = 123
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'bbb = ?'" do
        @result.sql.should == 'bbb = ?'
      end
      it "should have bound variables in Array [123]" do
        @result.bound_variables.should == [123]
      end
    end

    describe "and when :bbb param does not exist" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should also 'bbb = ?'" do
        @result.sql.should == 'bbb = ?'
      end
      it "should have bound variables in Array, accidentally [nil]" do
        @result.bound_variables.should == [nil]
      end
    end
  end



  describe "when parsed from '/*IF false*/aaa--ELSE bbb/*IF false*/ccc--ELSE ddd/*END*//*END*/'" do
    before do
      sql = "/*IF false*/aaa--ELSE bbb/*IF false*/ccc--ELSE ddd/*END*//*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      @result = @template.merge(@ctx)
    end

    it "parsed SQL should 'bbbddd'" do
      @result.sql.should == "bbbddd"
    end
  end



  describe "when parsed from 'SELECT * FROM emp/*BEGIN*/ WHERE /*IF false*/aaa-- ELSE AND deptno = 10/*END*//*END*/'" do
    before do
      sql = "SELECT * FROM emp/*BEGIN*/ WHERE /*IF false*/aaa-- ELSE AND deptno = 10/*END*//*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      @result = @template.merge(@ctx)
    end

    it "parsed SQL should 'SELECT * FROM emp WHERE  deptno = 10'" do
      @result.sql.should == "SELECT * FROM emp WHERE  deptno = 10"
    end
  end

  describe "when parsed from 'SELECT * FROM emp/*BEGIN*/ WHERE /*IF false*/aaa--- ELSE AND deptno = 10/*END*//*END*/'" do
    before do
      sql = "SELECT * FROM emp/*BEGIN*/ WHERE /*IF false*/aaa--- ELSE AND deptno = 10/*END*//*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      @result = @template.merge(@ctx)
    end

    it "parsed SQL should 'SELECT * FROM emp WHERE  deptno = 10'" do
      @result.sql.should == "SELECT * FROM emp WHERE  deptno = 10"
    end
  end



  describe "when parsed from 'SELECT * FROM emp/*BEGIN*/ WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'/*END*//*IF ctx[:deptno]*/ AND deptno = /*ctx[:deptno]*/20/*END*//*END*/'" do
    before do
      sql = "SELECT * FROM emp/*BEGIN*/ WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'/*END*//*IF ctx[:deptno]*/ AND deptno = /*ctx[:deptno]*/20/*END*//*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when context is empty (no param exists)" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp'" do
        @result.sql.should == 'SELECT * FROM emp'
      end
      it "bound variables should be empty" do
        @result.bound_variables.should be_empty
      end
    end

    describe "and when :job param exists" do
      before do
        @ctx[:job] = "HOGE"
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE job = ?'" do
        @result.sql.should == 'SELECT * FROM emp WHERE job = ?'
      end
      it "should have bound variables in Array ['HOGE']" do
        @result.bound_variables.should == ['HOGE']
      end
    end

    describe "and when :job and :deptno param exists" do
      before do
        @ctx[:job] = "HOGE"
        @ctx[:deptno] = 20
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE job = ? AND deptno = ?'" do
        @result.sql.should == 'SELECT * FROM emp WHERE job = ? AND deptno = ?'
      end
      it "should have bound variables in Array ['HOGE',20]" do
        @result.bound_variables.should == ['HOGE',20]
      end
    end

    describe "and when :job param does not exist and :deptno param exists" do
      before do
        @ctx[:deptno] = 20
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE  deptno = ?'" do
        @result.sql.should == 'SELECT * FROM emp WHERE  deptno = ?'
      end
      it "should have bound variables in Array [20]" do
        @result.bound_variables.should == [20]
      end
    end
  end



  describe "when parsed from '/*BEGIN*/WHERE /*IF true*/aaa BETWEEN /*ctx[:bbb]*/111 AND /*ctx[:ccc]*/123/*END*//*END*/'" do
    before do
      sql = "/*BEGIN*/WHERE /*IF true*/aaa BETWEEN /*ctx[:bbb]*/111 AND /*ctx[:ccc]*/123/*END*//*END*/"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :job and :deptno param exists" do
      before do
        @ctx[:bbb] = 300
        @ctx[:ccc] = 400
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'WHERE aaa BETWEEN ? AND ?'" do
        @result.sql.should == "WHERE aaa BETWEEN ? AND ?"
      end
      it "should have bound variables in Array [300,400]" do
        @result.bound_variables.should == [300,400]
      end
    end

    describe "and when :job and :deptno param does not exist" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'WHERE aaa BETWEEN ? AND ?'" do
        @result.sql.should == "WHERE aaa BETWEEN ? AND ?"
      end
      it "should have bound variables in Array, accidentally [nil,nil]" do
        @result.bound_variables.should == [nil,nil]
      end
    end

  end



  describe "when parsed from 'SELECT * FROM emp WHERE deptno IN /*ctx[:deptnoList]*/(10, 20) ORDER BY ename'" do
    before do
      sql = "SELECT * FROM emp WHERE deptno IN /*ctx[:deptnoList]*/(10, 20) ORDER BY ename"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :deptnoList param is [30,40,50]" do
      before do
        @ctx[:deptnoList] = [30,40,50]
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE deptno IN (?, ?, ?) ORDER BY ename'" do
        @result.sql.should == "SELECT * FROM emp WHERE deptno IN (?, ?, ?) ORDER BY ename"
      end
      it "should have bound variables in Array [30,40,50]" do
        @result.bound_variables.should == [30,40,50]
      end
    end

    describe "and when :deptnoList param is [30]" do
      before do
        @ctx[:deptnoList] = [30]
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE deptno IN (?) ORDER BY ename'" do
        @result.sql.should == "SELECT * FROM emp WHERE deptno IN (?) ORDER BY ename"
      end
      it "should have bound variables in Array [30]" do
        @result.bound_variables.should == [30]
      end
    end

    describe "and when :deptnoList param is empty" do
      before do
        @ctx[:deptnoList] = []
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE deptno IN  ORDER BY ename' and *CAUSES SYNTAX ERROR* (use IF comment to avoid this)" do
        @result.sql.should == "SELECT * FROM emp WHERE deptno IN  ORDER BY ename"
      end
      it "bound variables should be empty" do
        @result.bound_variables.should be_empty
      end
    end

    describe "and when :deptnoList param does not exist" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE deptno IN  ORDER BY ename' and *CAUSES SYNTAX ERROR* (use IF comment to avoid this)" do
        @result.sql.should == "SELECT * FROM emp WHERE deptno IN  ORDER BY ename"
      end
      it "bound variables should be empty" do
        @result.bound_variables.should be_empty
      end
    end

  end



  describe "when parsed from 'SELECT * FROM emp WHERE ename IN /*ctx[:enames]*/('SCOTT','MARY') AND job IN /*ctx[:jobs]*/('ANALYST', 'FREE')'" do
    before do
      sql = "SELECT * FROM emp WHERE ename IN /*ctx[:enames]*/('SCOTT','MARY') AND job IN /*ctx[:jobs]*/('ANALYST', 'FREE')"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :enames param is ['DAVE', 'MARY', 'SCOTT'] and :jobs param is ['MANAGER', 'ANALYST']" do
      before do
        @ctx[:enames] = ['DAVE', 'MARY', 'SCOTT']
        @ctx[:jobs] = ['MANAGER', 'ANALYST']
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp WHERE ename IN (?, ?, ?) AND job IN (?, ?)'" do
        @result.sql.should == "SELECT * FROM emp WHERE ename IN (?, ?, ?) AND job IN (?, ?)"
      end
      it "should have bound variables in Array ['DAVE', 'MARY', 'SCOTT', 'MANAGER', 'ANALYST']" do
        @result.bound_variables.should == ['DAVE', 'MARY', 'SCOTT', 'MANAGER', 'ANALYST']
      end
    end
  end



  describe "when parsed from 'INSERT INTO ITEM (ID, NUM) VALUES (/*ctx[:id]*/1, /*ctx[:num]*/20)'" do
    before do
      sql = "INSERT INTO ITEM (ID, NUM) VALUES (/*ctx[:id]*/1, /*ctx[:num]*/20)"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when :id param is 0 and :num param is 1" do
      before do
        @ctx[:id] = 0
        @ctx[:num] = 1
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'INSERT INTO ITEM (ID, NUM) VALUES (?, ?)'" do
        @result.sql.should == "INSERT INTO ITEM (ID, NUM) VALUES (?, ?)"
      end
      it "should have bound variables in Array [0, 1]" do
        @result.bound_variables.should == [0, 1]
      end
    end
  end



  describe "when parsed from SQL with embedded variable comment '/*$ctx[:aaa]*/foo'" do
    before do
      sql = "/*$ctx[:aaa]*/foo"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and :aaa param is 'hoge'" do
      before do
        @ctx[:aaa] = 'hoge'
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'hoge'" do
        @result.sql.should == "hoge"
      end
    end
  end



  describe "when parsed from SQL with embedded variable comment 'BETWEEN sal ? AND ?'" do
    before do
      sql = "BETWEEN sal ? AND ?"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and ctx[1] = 0 and ctx[2] = 1000 (note: key starts with 1, not 0.)" do
      before do
        @ctx[1] = 0
        @ctx[2] = 1000
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'BETWEEN sal ? AND ?'" do
        @result.sql.should == "BETWEEN sal ? AND ?"
      end
      it "should have bound variables in Array [0, 1000]" do
        @result.bound_variables.should == [0, 1000]
      end
    end
  end



  describe "when parsed from 'SELECT * FROM emp/*hoge'" do
    it "should cause parse error" do
      lambda {
        TwoWaySQL::Template.parse("SELECT * FROM emp/*hoge")
      }.should raise_error(Racc::ParseError)
    end
  end



  describe "when parsed from '/*BEGIN*/'" do
    it "should cause parse error" do
      lambda {
        TwoWaySQL::Template.parse("/*BEGIN*/")
      }.should raise_error(Racc::ParseError)
    end
  end



  describe "when parse SQL with semicolon, " do
    describe "that ends with semicolon like 'SELECT * FROM emp;'" do
      before do
        sql = "SELECT * FROM emp;"
        @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
        @result = @template.merge(@ctx)
      end
      it "should strip semicolon at input end" do
        @result.sql.should == "SELECT * FROM emp"
      end
    end

    describe "that ends with semicolon and tab like 'SELECT * FROM emp;\t'" do
      before do
        sql = "SELECT * FROM emp;\t"
        @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
        @result = @template.merge(@ctx)
      end
      it "should strip semicolon and tab at input end" do
        @result.sql.should == "SELECT * FROM emp"
      end
    end

    describe "that ends with semicolon and spaces like 'SELECT * FROM emp; '" do
      before do
        sql = "SELECT * FROM emp; "
        @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
        @result = @template.merge(@ctx)
      end
      it "should strip semicolon and spaces at input end" do
        @result.sql.should == "SELECT * FROM emp"
      end
    end
  end



  describe "various characters" do
    describe " '<>' " do
      before do
        sql = "SELECT * FROM emp WHERE job <> /*ctx[:job]*/'CLERK'"
        @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
        @ctx[:job] = "HOGE"
        @result = @template.merge(@ctx)
      end

      it "SQL will 'SELECT * FROM emp WHERE job <> ?'" do
        @result.sql.should == "SELECT * FROM emp WHERE job <> ?"
      end

      it "should have two bound variables in Array ['HOGE']" do
        @result.bound_variables.should == ["HOGE"]
      end
    end


    describe "minus, such as -5 " do
      before do
        sql = "SELECT * FROM statistics WHERE degree = /*ctx[:degree]*/-5"
        @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
        @ctx[:degree] = -10
        @result = @template.merge(@ctx)
      end

      it "SQL will 'SELECT * FROM statistics WHERE degree = ?'" do
        @result.sql.should == "SELECT * FROM statistics WHERE degree = ?"
      end

      it "should have two bound variables in Array [-10]" do
        @result.bound_variables.should == [-10]
      end
    end


    describe "quote escape, such as 'Let''s' " do
      before do
        sql = "SELECT * FROM comments WHERE message = /*ctx[:message]*/'Let''s GO'"
        @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
        @ctx[:message] = "Hang'in there"
        @result = @template.merge(@ctx)
      end

      it "SQL will 'SELECT * FROM comments WHERE message = ?'" do
        @result.sql.should == "SELECT * FROM comments WHERE message = ?"
      end

      it "should have two bound variables in Array ['Hang'in there']" do
        @result.bound_variables.should == ["Hang'in there"]
      end
    end

  end



  describe "when parsed from 'SELECT * FROM emp -- comments here'" do
    before do
      sql = "SELECT * FROM emp -- comments here"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
    end

    describe "and when 'job' param does not exist" do
      before do
        @result = @template.merge(@ctx)
      end
      it "parsed SQL should 'SELECT * FROM emp -- comments here'" do
        @result.sql.should == 'SELECT * FROM emp -- comments here'
      end
      it "bound variables should be empty" do
        @result.bound_variables.should be_empty
      end
    end
  end


  describe "when parsed from 'SELECT * FROM emp WHERE empno = /*ctx[:empno]*/5.0 AND 1 = 1'" do
    before do
      sql = "SELECT * FROM emp WHERE empno = /*ctx[:empno]*/5.0 AND 1 = 1"
      @template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)
      
      @ctx[:empno] = 7788
      @result = @template.merge(@ctx)
    end

    it "parsed SQL should 'SELECT * FROM emp WHERE empno = ? AND 1 = 1'" do
      @result.sql.should == 'SELECT * FROM emp WHERE empno = ? AND 1 = 1'
    end

    it "should have bound variables in Array [7788]" do
      @result.bound_variables.should == [7788]
    end
  end



  describe "space compaction mode" do
    describe "compaction of space node" do
      before do
        sql = <<-EOS
SELECT
  *
FROM
  emp
WHERE
  job    =   /*ctx[:job]*/'CLERK'
  AND   deptno   =   /*ctx[:deptno]*/10
EOS
        @template = TwoWaySQL::Template.parse(sql, :compact_mode => true)
        @ctx[:job] = 'MANAGER'
        @ctx[:deptno] = 30
        @result = @template.merge(@ctx)
      end

      it  do
        @result.sql.should == "SELECT * FROM emp WHERE job = ? AND deptno = ?"
        @result.bound_variables.should == ["MANAGER", 30]
      end
    end

    describe "treat line end as one space" do
      before do
        sql = <<-EOS
SELECT
*
FROM
emp
WHERE
job    =   /*ctx[:job]*/'CLERK'
AND   deptno   =   /*ctx[:deptno]*/10
EOS
        @template = TwoWaySQL::Template.parse(sql, :compact_mode => true)
        @ctx[:job] = 'MANAGER'
        @ctx[:deptno] = 30
        @result = @template.merge(@ctx)
      end

      it  do
        @result.sql.should == "SELECT * FROM emp WHERE job = ? AND deptno = ?"
        @result.bound_variables.should == ["MANAGER", 30]
      end
    end

  end


  describe "multiline actual comment" do
    before do
      sql = <<-EOS
SELECT
  *
FROM
  emp
  /* 
     This is
     multiline comment
  */
WHERE
  job    =   /*ctx[:job]*/'CLERK'
  AND   deptno   =   /*ctx[:deptno]*/10
EOS
      @template = TwoWaySQL::Template.parse(sql, :compact_mode => true)
      @ctx[:job] = 'MANAGER'
      @ctx[:deptno] = 30
      @result = @template.merge(@ctx)
    end

    it "handle multiline comment then ignore it if @preserve_comment is falsy" do
      @result.sql.should == "SELECT * FROM emp  WHERE job = ? AND deptno = ?"
      @result.bound_variables.should == ["MANAGER", 30]
    end

  end


end
