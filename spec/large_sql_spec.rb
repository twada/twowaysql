require File.dirname(__FILE__) + '/spec_helper.rb'


describe TwoWaySQL::Template do

  describe "multi-line SQL and preserve space example" do

    before do
      @sql = <<-EOS
SELECT DISTINCT
  i.id AS item_id
  ,d.display_name AS display_name
  ,h.status AS status_id
  ,i.unique_name AS unique_name
  ,i.created_on
FROM
  some_schema.item i
  INNER JOIN some_schema.item_detail d
    ON i.id = d.item_id
  INNER JOIN some_schema.item_history h
    ON i.id = h.item_id

/*BEGIN*/WHERE
  /*IF ctx[:name] */i.name ILIKE /*ctx[:name]*/'hoge%'/*END*/
  /*IF ctx[:display_name] */AND d.display_name ILIKE /*ctx[:display_name]*/'hoge%'/*END*/
  /*IF ctx[:status] */AND h.status IN /*ctx[:status]*/(3, 4, 9)/*END*/
  /*IF ctx[:ignore_status] */AND h.status NOT IN /*ctx[:ignore_status]*/(4, 9)/*END*/
/*END*/

/*IF ctx[:order_by] */ ORDER BY /*$ctx[:order_by]*/i.id /*$ctx[:order]*/ASC /*END*/
/*IF ctx[:limit] */ LIMIT /*ctx[:limit]*/10/*END*/
/*IF ctx[:offset] */ OFFSET /*ctx[:offset]*/0/*END*/
EOS
    end


    describe '' do
      before do
        template = TwoWaySQL::Template.parse(@sql)
        @result = template.merge(:name => "HOGE", :status => [3, 4])
      end

      it "sql" do
        expected = <<-EOS
SELECT DISTINCT
  i.id AS item_id
  ,d.display_name AS display_name
  ,h.status AS status_id
  ,i.unique_name AS unique_name
  ,i.created_on
FROM
  some_schema.item i
  INNER JOIN some_schema.item_detail d
    ON i.id = d.item_id
  INNER JOIN some_schema.item_history h
    ON i.id = h.item_id

WHERE
  i.name ILIKE ?
  
  AND h.status IN (?, ?)
  





EOS
        @result.sql.should == expected
      end

      it "bound_variables" do
        @result.bound_variables.should == ["HOGE", 3, 4]
      end
    end
  end




  describe "a little complex UPDATE statement example" do

    before do
      @sql = <<-EOS
UPDATE
  some_schema.item

SET
  display_order =
    CASE display_order
      WHEN NULL THEN 1 + /*ctx[:target_id_list].size*/1
      ELSE display_order + /*ctx[:target_id_list].size*/1
    END
  ,updated_on = CURRENT_TIMESTAMP
  ,updated_by = /*ctx[:account_id]*/999

WHERE
  item_id IN /*ctx[:item_id_list]*/(25,26,27)
  /*IF ctx[:status_id] */AND status_id = /*ctx[:status_id]*/100/*END*/
EOS
    end

    describe '' do
      before do
        template = TwoWaySQL::Template.parse(@sql)
        data = {
          :target_id_list => [11,12,13],
          :item_id_list => [31,32,33,34],
          :account_id => 50,
          :status_id => 2
        }
        @result = template.merge(data)
      end

      it "sql" do
        expected = <<-EOS
UPDATE
  some_schema.item

SET
  display_order =
    CASE display_order
      WHEN NULL THEN 1 + ?
      ELSE display_order + ?
    END
  ,updated_on = CURRENT_TIMESTAMP
  ,updated_by = ?

WHERE
  item_id IN (?, ?, ?, ?)
  AND status_id = ?
EOS
        @result.sql.should == expected
      end

      it "bound_variables" do
        @result.bound_variables.should == [3, 3, 50, 31, 32, 33, 34, 2]
      end
    end
  end



  describe "bugfix: case insensitive match for SQL reserved words" do
    before do
      sql = <<-EOS
select
  *
from
  hoge
/*BEGIN*/where
  /*IF ctx[:name] */name like /*ctx[:name]*/'hoge%'/*END*/
  /*IF ctx[:id_list] */and id in /*ctx[:id_list]*/(3, 4, 9)/*END*/
/*END*/
EOS
      @template = TwoWaySQL::Template.parse(sql)
    end

    it "if both line is true" do
      expected = <<-EOS
select
  *
from
  hoge
where
  name like ?
  and id in (?, ?)

EOS
      @result = @template.merge(:name => 'foo%', :id_list => [10, 11])
      @result.sql.should == expected
      @result.bound_variables.should == ['foo%', 10, 11]
    end

    it "if second line is true" do
      expected = <<-EOS
select
  *
from
  hoge
where
  
   id in (?, ?)

EOS
      @result = @template.merge(:id_list => [10, 11])
      @result.sql.should == expected
      @result.bound_variables.should == [10, 11]
    end

  end




  describe "examples in website" do
    it '' do
  # given SQL string with TwoWaySQL comments
  sql = <<-EOS
    SELECT * FROM emp
    /*BEGIN*/WHERE
      /*IF ctx[:job]*/ job = /*ctx[:job]*/'CLERK' /*END*/
      /*IF ctx[:deptno_list]*/ AND deptno IN /*ctx[:deptno_list]*/(20, 30) /*END*/
      /*IF ctx[:age]*/ AND age > /*ctx[:age]*/30 /*END*/
    /*END*/
    /*IF ctx[:order_by] */ ORDER BY /*$ctx[:order_by]*/id /*$ctx[:order]*/ASC /*END*/
  EOS


  # parse the SQL to create template object
  template = TwoWaySQL::Template.parse(sql)


  # merge data with template
  data = {
    :age => 35,
    :deptno_list => [10,20,30],
    :order_by => 'age',
    :order => 'DESC'
  }
  merged = template.merge(data)


  expected_sql = <<-EOS
    SELECT * FROM emp
    WHERE
      
       deptno IN (?, ?, ?) 
       AND age > ? 
    
     ORDER BY age DESC 
  EOS

  merged.sql.should == expected_sql      #=> true
  merged.bound_variables.should == [10,20,30,35]
    end
  end




  describe "guess line number on multi-line SQL syntax error" do

    it "non-nested unmatched IF-END" do
      sql = <<-EOS
SELECT
  i.id AS item_id
  ,d.display_name AS display_name

FROM
  some_schema.item i
  INNER JOIN some_schema.item_detail d
    ON i.id = d.item_id

/*IF ctx[:order_by] */ ORDER BY /*$ctx[:order_by]*/i.id /*$ctx[:order]*/ASC   /* no END comment */
/*IF ctx[:limit] */ LIMIT /*ctx[:limit]*/10/*END*/
/*IF ctx[:offset] */ OFFSET /*ctx[:offset]*/0/*END*/
EOS
      begin
        TwoWaySQL::Template.parse(sql)
      rescue Racc::ParseError => e
        e.to_s.should =~ /line:\[10\]/
      end
    end


    it "no-END on input end" do
      sql = <<-EOS
SELECT
  i.id AS item_id
  ,d.display_name AS display_name

FROM
  some_schema.item i
  INNER JOIN some_schema.item_detail d
    ON i.id = d.item_id

/*IF ctx[:order_by] */ ORDER BY /*$ctx[:order_by]*/i.id /*$ctx[:order]*/ASC/*END*/
/*IF ctx[:limit] */ LIMIT /*ctx[:limit]*/10/*END*/
/*IF ctx[:offset] */ OFFSET /*ctx[:offset]*/0
EOS
      begin
        TwoWaySQL::Template.parse(sql)
      rescue Racc::ParseError => e
        e.to_s.should =~ /line:\[12\]/
        e.to_s.should =~ /OFFSET \/\*ctx\[:offset\]\*\/0/
        
      end
    end


    it "unmatched BEGIN-END" do
      sql = <<-EOS
SELECT DISTINCT
  i.id AS item_id
  ,d.display_name AS display_name
  ,h.status AS status_id
  ,i.unique_name AS unique_name
  ,i.created_on
FROM
  some_schema.item i
  INNER JOIN some_schema.item_detail d
    ON i.id = d.item_id
  INNER JOIN some_schema.item_history h
    ON i.id = h.item_id

/*BEGIN*/WHERE  /* line:14 */
  /*IF ctx[:name] */i.name ILIKE /*ctx[:name]*/'hoge%'/*END*/
  /*IF ctx[:display_name] */AND d.display_name ILIKE /*ctx[:display_name]*/'hoge%'/*END*/
  /*IF ctx[:status] */AND h.status IN /*ctx[:status]*/(3, 4, 9)  /* no-END at line:17 */
  /*IF ctx[:ignore_status] */AND h.status NOT IN /*ctx[:ignore_status]*/(4, 9)/*END*/
/*END*/

/*IF ctx[:order_by] */ ORDER BY /*$ctx[:order_by]*/i.id /*$ctx[:order]*/ASC /*END*/
/*IF ctx[:limit] */ LIMIT /*ctx[:limit]*/10/*END*/
/*IF ctx[:offset] */ OFFSET /*ctx[:offset]*/0/*END*/
EOS
      begin
        TwoWaySQL::Template.parse(sql)
      rescue Racc::ParseError => e
        # unmatched END is at line 17 but value stack indicates open BEGIN statement
        e.to_s.should =~ /line:\[14\]/
      end
    end

  end


end
