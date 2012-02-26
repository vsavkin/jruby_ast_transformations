# Ast Transformations

This project demonstrates what you can do with the Ruby language having such a powerful tool as AST transformations. Many languages support AST transformations. LISP macros is one of the most well-known examples. Though it is impossible to support AST transformations as well as LISP does it, still many cool things can be done. If you want an example, take a look at the Groovy programming language and Spock testing framework.

# Example

Let's add named arguments to the Ruby language. 

file_to_transform.rb

	class MyClass
	  def my_method name, age
	    puts name
	    puts age
	  end
	end


main.rb

	require_relative 'ast_transformations'
	load File.dirname(__FILE__) + "/file_to_transform.rb"

	MyClass.new.my_method age: 25, name: "Victor"

If you are curious about the implementation, check out ast_transformations.rb. Though the implementation is naive and not full, it shows how easy it is to extend a language using AST transformations.