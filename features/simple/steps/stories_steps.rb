require File.dirname(__FILE__) + '/../../feature_helper.rb'

Before do
  @ctx = {}
end

After do
end

Given /template is (.*)/ do |text|
  @template = TwoWaySQL::Template.parse(text)
end

Given /modify context (.*)/ do |exp|
  ctx = @ctx
  eval(exp)
end

When /template merged with context/ do
  @result = @template.merge(@ctx)
end

Then /merged sql should be (.*)/ do |text|
  @result.sql.should == text
end

Then /bound variables should be (.*)/ do |exp|
  @result.bound_variables.should == eval(exp)
end
