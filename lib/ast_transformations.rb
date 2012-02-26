require 'java'
require_relative '../jars/jrubyparser-0.2.jar'

module AstTransformations
  import org.jrubyparser.rewriter.ReWriteVisitor

  class NamedArgumentsVisitor < ReWriteVisitor
    include_package "org.jrubyparser.ast"
    import org.jrubyparser.SourcePosition

    def visitDefnNode(node)
      args = node.args_node
      body = node.body_node

      new_args = transform_arguments(args)
      new_body = transform_body(args, body)
      new_defn_node = DefnNode.new(node.position, node.name_node, new_args, node.scope, new_body)

      super new_defn_node
    end

    private

    def transform_arguments(args)
      arg_nodes = args.child_nodes.first.child_nodes
      new_argument = ArgumentNode.new(arg_nodes.first.position, "__named_arguments__")
      new_pre = ListNode.new(args.pre.position, new_argument)
      ArgsNode.new(args.position, new_pre, args.optional, args.rest, args.post, args.block)
    end

    def transform_body(args, body)
      assignments = generate_assignments(args)
      BlockNode.new(pos).tap do |new_body|
        insert_assignments(assignments, new_body)
        insert_old_body(body, new_body)
      end
    end

    def generate_assignments(args)
      arg_names(args).map do |name|
        LocalAsgnNode.new(pos, name, 0, call_to_hash(name))
      end
    end

    def insert_assignments(assignments, new_body)
      assignments.each do |a|
        line = NewlineNode.new(pos, a)
        new_body.add(line)
      end
    end

    def insert_old_body(body, new_body)
      new_body.add(body)
    end

    def call_to_hash(name)
      call_args = ArrayNode.new(pos, SymbolNode.new(pos, name))
      receiver = LocalVarNode.new(pos, 0, "__named_arguments__")
      CallNode.new(pos, receiver, "[]", call_args)
    end

    def arg_names(args)
      arg_nodes = args.child_nodes.first.child_nodes
      arg_nodes.map(&:name)
    end

    def pos
      SourcePosition.new
    end
  end

  module Preprocessor
    extend self

    import org.jrubyparser.parser.ParserConfiguration
    import org.jrubyparser.Parser
    import org.jrubyparser.CompatVersion
    import java.io.StringReader
    import java.io.StringWriter

    def preprocess file_name, source
      ast = parse_ast(file_name, source)
      writer = StringWriter.new
      visitor = NamedArgumentsVisitor.new(writer, source)
      ast.accept(visitor)
      writer.to_s
    end

    private
    def parse_ast file_name, source
      config = ParserConfiguration.new(1, CompatVersion::RUBY1_9)
      reader = StringReader.new(source)
      Parser.new.parse(file_name, reader, config)
    end
  end
end

def load file_name
  source = File.read(file_name)
  transformed_source = AstTransformations::Preprocessor.preprocess(file_name, source)
  eval(transformed_source, binding, file_name, 1)
end
