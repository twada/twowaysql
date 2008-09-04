= TwoWaySQL

=== sites:
* {Web Site}[http://twowaysql.rubyforge.org/]
* {Project Page}[http://rubyforge.org/projects/twowaysql]
* {API Doc}[http://twowaysql.rubyforge.org/rdoc/]
* {Issue Tracking}[http://twowaysql.rubyforge.org/issues/]

=== sources:
* http://github.com/twada/twowaysql/tree/master



== DESCRIPTION:


=== What is TwoWaySQL

'TwoWaySQL' is a concept, looks like a Template Engine for SQL.

It is initially invented and implemented in Seasar project's S2Dao[http://s2dao.seasar.org/en/index.html].

This package is a Ruby implementation of TwoWaySQL concept.


=== Why TwoWaySQL

Like any other technology, SQL is also in 80:20 world. 80% of SQL can be generated easily and automatically by O-R Mappers, 20% can not. 20% of your SQLs may large and complex, using CASE clause, self JOIN, UNION ALL, EXCEPT, ... these are the real strength of SQL and its set-based operations.

We better use them, to get the most out of RDBMS power.

TwoWaySQL encourages to write complex SQL manually. Just develop SQL using tools like pgAdmin3 in try and error style, then markup the SQL by TwoWaySQL. Usage and Features are in this doc.



=== Advantage
TwoWaySQL provides better separation of host language and SQL.

With TwoWaySQL, you can
* separate SQL (as file) from host language
* bind variables to SQL using Substitution comments
* modify SQL conditionally by using Directive comments
* run and preview TwoWaySQL-style SQL by tools like pgAdmin3, since the SQL is still valid SQL.



== One minute example

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

  merged.sql == expected_sql      #=> true
  merged.bound_variables          #=> [10,20,30,35]


  # use merged SQL and variables with any O-R Mapper you like (ex. Sequel)
  require 'sequel'
  DB = Sequel.connect('postgres://user:pass@localhost:5432/mydb')
  rows = DB.fetch(merged.sql, *merged.bound_variables).all
  . . .


==== What TwoWaySQL intended to do
* TwoWaySQL is intended to be a small and simple module.
* TwoWaySQL respects SQL and its set-based operations. TwoWaySQL assists writing complex SQL with ease.
* TwoWaySQL is not a replacement of ActiveRecord,Sequel,or any other O-R Mappers. Instead, TwoWaySQL will work with O-R Mappers well as a SQL construction module.


==== What TwoWaySQL is not
TwoWaySQL is not
* an O-R Mapper
* a SQL Parser
* a framework
* a Prepared Statement



== FEATURES/PROBLEMS:

* Substitution comments
  * Bind variable comment
  * Embedded variable comment

* Directive comments
  * IF comment
  * ELSE comment
  * BEGIN comment

* actual SQL comment


=== Known limitations

* currently, ruby version of TwoWaySQL cannot parse multi-line comments.



== SYNOPSIS:

NOTE: some of this section is based on docs for S2Dao[http://s2dao.seasar.org/en/s2dao.html#SQLBind]


=== Published Classes

TwoWaySQL::Template is the class you may only use. TwoWaySQL::Template acts as a Facade for this package, others are for internal use.


=== Basic Usage

==== Input
* TwoWaySQL-style SQL(string,file or anything like IO) to TwoWaySQL::Template.parse to create template object (note: template object is stateless and reentrant, so you can cache it)
  * (Optionally) TwoWaySQL::Template.parse accepts Hash of parse options as second argument
* data object(Hash-like object) to the TwoWaySQL::Template#merge then TwoWaySQL will evaluate the data as 'ctx'.

==== Output
* SQL String with placeholders (generally, '?' is used for placeholders)
* Array of bound variables for placeholders



=== SQL comment

Firstly, In TwoWaySQL, expressions are written within SQL comment such as within "/**/" and "--". SQL may still be executed since TwoWaySQL specific, non-SQL expressions are written within comments. As a best practice, it is better to first write and test SQL and then write expressions within comments.

To write actual comments in SQL, *insert a space* after "/*" before the comment string. For example, /* hoge*/. TwoWaySQL will recognize the space(s) after the comment start ("/*") and treat the enclosed content as an actual comment.



=== Bind variable comment

Bind variable comment is used to bind value(s) to the SQL.
Literal to the right of bind variable comment is automatically replaced with a value.
Bind variable comment syntax is as follows:

  /*variable_name*/Literal

TwoWaySQL may use bind variable as follows. In this case, value of ctx[:empno] is automatically set. Data object that is passed to TwoWaySQL::Template#merge is evaled as name 'ctx'.

  SELECT * FROM emp WHERE empno = /*ctx[:empno]*/7788

===== usage

  sql = "SELECT * FROM emp WHERE job = /*ctx[:job]*/'CLERK' AND deptno = /*ctx[:deptno]*/20"
  template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)

  merged = template.merge(:job => "HOGE", :deptno => 30)
  merged.sql                #=> "SELECT * FROM emp WHERE job = ? AND deptno = ?"
  merged.bound_variables    #=> ["HOGE", 30]



==== IN clause

To bind multiple values in an IN clause, you can also use bind variable comment as well.

  IN /*argument name*/(...)

TwoWaySQL may use bind variable as follows. In this case, ctx[:names] is automatically replaced with placeholders associated with number of values in the data.

  IN /*ctx[:names]*/('aaa', 'bbb')

acceptable argument for IN clause is an array-like object. Say, Object that respond_to 'to_ary'.

===== usage

  sql = "SELECT * FROM emp WHERE deptno IN /*ctx[:deptnoList]*/(10, 20) ORDER BY ename"
  template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)

  merged = template.merge(:deptnoList => [30,40,50])
  merged.sql                #=> "SELECT * FROM emp WHERE deptno IN (?, ?, ?) ORDER BY ename"
  merged.bound_variables    #=> [30,40,50]

  merged2 = template.merge(:deptnoList => [80])
  merged2.sql                #=> "SELECT * FROM emp WHERE deptno IN (?) ORDER BY ename"
  merged2.bound_variables    #=> [80]


==== LIKE

If you want to use "LIKE", you may write bind variables:

  ename LIKE /*ctx[:ename]*/'hoge'

Unfortunately, there is no special support for "LIKE". So, to use a wildcard character, add wildcard directy to the data. For example, to specify to include "COT", add wildcard character in the value as follows:

  :ename => "%COT%"



==== Embedded variable comment

You can use Embedded variable comment to embed value directly (say without quoting or escaping) into the SQL as a string. Literal to the right of the Embedded variable comment will be replaced with value. Embedded variable comment has the following syntax:

  /*$variable name*/Literal

===== CAUTION:
As you noticed. Embedded variable comment has risk for SQL Injection. Please note, like any other 'eval' usage of TwoWaySQL, Embedded variable comment evals the data in safe level 4. Therefore, dangerous actions in Ruby world (ex. system call, valiable assignments, tainted strings) are never executed. However, this is not enough. Valid ruby string is still dangerous string as SQL fragments. Do NOT use user input or any other strings outside your code. If you use Embedded variable comment, you should carefully check the data and its origin.

===== usage

  sql = "SELECT * FROM emp ORDER BY /*$ctx[:order_by]*/ename /*$ctx[:order]*/ASC"
  template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)

  merged = template.merge(:order_by => 'id, :order => 'DESC')
  merged.sql                #=> "SELECT * FROM emp ORDER BY id DESC"
  merged.bound_variables    #=> []



=== IF comment

To change SQL during execution based on a condition, use IF comments. IF comment has the following syntax:

  /*IF condition*/ .../*END*/

An example of IF comment is as follows:

  /*IF ctx[:foo]*/hoge = /*ctx[:hoge]*/'abc'/*END*/

When the condition returns a truthy value, TwoWaySQL treats statements in "/*IF*/" and "/*END*/" as active. In the above example, "hoge = /*ctx[:hoge]*/'abc'" will be output only when 'eval(ctx[:foo])' retuens an truthy value.


==== usage

  sql = "SELECT * FROM emp/*IF ctx[:job] */ WHERE job = /*ctx[:job]*/'CLERK'/*END*/"
  template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)


  # active case
  merged = template.merge(:job => 'MANAGER')
  merged.sql                 #=> 'SELECT * FROM emp WHERE job = ?'
  merged.bound_variables     #=> ['MANAGER']

  # inactive case
  ctx = {}
  merged2 = template.merge(ctx)
  merged2.sql                #=> 'SELECT * FROM emp'
  merged2.bound_variables    #=> []



=== ELSE comment

You can use ELSE comment to activate statements when condition is false. Sn example of IF comment with ELSE is as follows.

  /*IF ctx[:foo]*/hoge = /*ctx[:hoge]*/'abc'
    -- ELSE hoge IS NULL
  /*END*/

In this case, when the eval(ctx[:foo]) returns an falsy value, string "hoge IS NULL" will be active.


==== ELSE comment sample

  sql = "SELECT * FROM emp WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'-- ELSE job IS NULL/*END*/"
  template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)

  # active case
  merged = template.merge(:job => 'MANAGER')
  merged.sql                 #=> 'SELECT * FROM emp WHERE job = ?'
  merged.bound_variables     #=> ['MANAGER']

  # inactive case
  ctx = {}
  merged2 = template.merge(ctx)
  merged2.sql                #=> 'SELECT * FROM emp WHERE job IS NULL'
  merged2.bound_variables    #=> []




=== BEGIN comment

BEGIN comment is used to not output WHERE clause when all IF comment in a WHERE clause, which does not include an ELSE, is false. BEGIN comment should used with IF comment.

BEGIN comment syntax is as follows:

  /*BEGIN*/WHERE clause/*END*/

So, BEGIN comment example is as follows:

  /*BEGIN*/WHERE
    /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'/*END*/
    /*IF ctx[:deptno]*/AND deptno = /*ctx[:deptno]*/20/*END*/
  /*END*/

In the above example, 
* when job and deptno are nil, WHERE clause will not be outputted.
* When ctx[:job] == nil and ctx[:deptno] != nil, then sql will "WHERE depno = ?".
* When ctx[:job] != nil and ctx[:deptno] == nil, then sql will "WHERE job = ?".
* When ctx[:job] != nil and ctx[:deptno] != nil, then sql will "WHERE job = ? AND depno = ?".


==== usage

  sql = "SELECT * FROM emp/*BEGIN*/ WHERE /*IF ctx[:job]*/job = /*ctx[:job]*/'CLERK'/*END*//*IF ctx[:deptno]*/ AND deptno = /*ctx[:deptno]*/20/*END*//*END*/"
  template = TwoWaySQL::Template.parse(sql, :preserve_eol => false)

  # when data is empty (no param exists)
  ctx = {}
  merged = template.merge(ctx)
  merged.sql                 #=> 'SELECT * FROM emp'
  merged.bound_variables     #=> []

  # when :job param exists
  merged2 = template.merge(:job => 'MANAGER')
  merged2.sql                #=> 'SELECT * FROM emp WHERE job = ?'
  merged2.bound_variables    #=> ['MANAGER']

  # when :job and :deptno param exists
  ctx3 = {}
  ctx3[:job] = "MANAGER"
  ctx3[:deptno] = 20
  merged3 = template.merge(ctx3)
  merged3.sql                #=> 'SELECT * FROM emp WHERE job = ? AND deptno = ?'
  merged3.bound_variables    #=> ['MANAGER',20]



== REQUIREMENTS:

* racc/parser (basically bundled with ruby)


== INSTALL:

* sudo gem install twowaysql


== AUTHOR:

* Takuto Wada(takuto.wada at gmail dot com)


== LICENSE:

Copyright 2004-2008 the Seasar Foundation and the Others.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
either express or implied. See the License for the specific language
governing permissions and limitations under the License.
