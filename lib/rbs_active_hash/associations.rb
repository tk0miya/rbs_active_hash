# frozen_string_literal: true

require "rbs"

module RbsActiveHash
  module Associations
    class AssociationDefinition < RBS::AST::Members::Include
    end

    class RB < RBS::Prototype::RB
      def process(node, decls:, comments:, context:)
        case node.type
        when :FCALL, :VCALL
          case node.children.first
          when :has_many, :has_one, :belongs_to
            decls << AssociationDefinition.new(
              name: RBS::TypeName.new(name: node.children.first, namespace: RBS::Namespace.root),
              args: node.children[1],
              annotations: [],
              location: nil,
              comment: nil
            )
          else
            super
          end
        else
          super
        end
      end
    end

    class Parser
      attr_reader :has_many, :has_one, :belongs_to

      def initialize
        @has_many = []
        @has_one = []
        @belongs_to = []
      end

      def parse(string, target)
        parser = RB.new
        parser.parse(string)
        parser.decls.each do |decl|
          process(decl, target)
        end
      end

      def process(node, target)
        case node
        when RBS::AST::Declarations::Module, RBS::AST::Declarations::Class
          name = node.name.split
          if target[...name.size] == name
            node.members.each do |member|
              process(member, target[name.size...].to_a)
            end
          end
        when AssociationDefinition
          process_association_definition(node) if target.empty?
        end
      end

      def process_association_definition(node)
        case node.name.name
        when :has_many
          association_id, args = node_to_literal(node.args)
          @has_many << [association_id, args.to_h]
        when :has_one
          association_id, args = node_to_literal(node.args)
          @has_one << [association_id, args.to_h]
        when :belongs_to
          association_id, args = node_to_literal(node.args)
          @belongs_to << [association_id, args.to_h]
        end
      end

      def node_to_literal(node)
        case node.type
        when :LIST
          node.children[...-1].map { |child| node_to_literal(child) }
        when :LIT, :STR
          node.children.first
        when :HASH
          Hash[*node_to_literal(node.children.first)]
        else
          node
        end
      end
    end
  end
end
