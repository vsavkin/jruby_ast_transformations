require_relative 'ast_transformations'
load File.dirname(__FILE__) + "/file_to_transform.rb"

MyClass.new.my_method age: 25, name: "Victor"
