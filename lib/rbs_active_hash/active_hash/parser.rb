# frozen_string_literal: true

require "rbs"

module RbsActiveHash
  module ActiveHash
    module Parser
      class AssociationDefinition < RBS::AST::Members::Include
      end

      class ScopeDefinition < RBS::AST::Members::Include
      end

      class RB < RBS::Prototype::RB
        # @rbs override
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
            when :scope
              decls << ScopeDefinition.new(
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
        attr_reader :has_many #: Array[[Symbol, Hash[untyped, untyped]]]
        attr_reader :has_one #: Array[[Symbol, Hash[untyped, untyped]]]
        attr_reader :belongs_to #: Array[[Symbol, Hash[untyped, untyped]]]
        attr_reader :scopes #: Array[[Symbol, Hash[untyped, untyped]]]

        def initialize #: void
          @has_many = []
          @has_one = []
          @belongs_to = []
          @scopes = []
        end

        # @rbs string: String
        # @rbs target: Array[Symbol]
        def parse(string, target) #: void
          parser = RB.new
          parser.parse(string)
          parser.decls.each do |decl|
            process(decl, target)
          end
        end

        # @rbs node: RBS::AST::Declarations::t | RBS::AST::Members::t
        # @rbs target: Array[Symbol]
        def process(node, target) #: void
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
          when ScopeDefinition
            process_scope_definition(node) if target.empty?
          end
        end

        # @rbs node: AssociationDefinition
        def process_association_definition(node) #: void
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

        # @rbs node: ScopeDefinition
        def process_scope_definition(node) #: void
          scope_id, args = node_to_literal(node.args)
          @scopes << [scope_id, args]
        end

        # @rbs node: untyped
        def node_to_literal(node) #: untyped
          case node.type
          when :LIST
            node.children[...-1].map { |child| node_to_literal(child) }
          when :LIT, :STR, :SYM
            node.children.first
          when :HASH
            Hash[*node_to_literal(node.children.first)]
          when :LAMBDA
            node.children.first.children.first # Convert to the list of argument names
          else
            node
          end
        end
      end
    end
  end
end
