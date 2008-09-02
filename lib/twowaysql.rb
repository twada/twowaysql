$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'twowaysql/node'
require 'twowaysql/parser'
require 'twowaysql/template'
