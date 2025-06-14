# frozen_string_literal: true

require "rbs"
require "active_hash"

module RbsActiveHash
  module ActiveHash
    # @rbs klass: singleton(ActiveHash::Base)
    def self.user_defined_model?(klass) #: bool
      klass.name !~ /^Active(Hash|File|JSON|Yaml)::/
    end

    # @rbs klass: singleton(ActiveHash::Base) -> String
    def self.class_to_rbs(klass) #: String
      Generator.new(klass).generate
    end

    class Generator
      attr_reader :klass #: singleton(ActiveHash::Base)
      attr_reader :klass_name #: String
      attr_reader :parser #: ActiveHash::Parser::Parser

      # @rbs klass: singleton(ActiveHash::Base)
      def initialize(klass) #: void
        @klass = klass
        @klass_name = klass.name || ""
        @parser = ActiveHash::Parser::Parser.new

        path, = Object.const_source_location(klass_name)
        return unless path

        @parser.parse(IO.read(path.to_s), klass_name.split("::").map(&:to_sym))
      end

      def generate #: String
        if klass < ::ActiveFile::Base
          begin
            klass.reload
          rescue StandardError
            nil
          end
        end

        format(klass_decl)
      end

      private

      # @rbs rbs: String
      def format(rbs) #: String
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      def klass_decl #: String
        <<~RBS
          #{header}
          #{enum_decls}
          #{scope_decls}
          #{association_decls}
          #{method_decls}
          #{footer}
        RBS
      end

      def header #: String
        namespace = +""
        klass_name.split("::").map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = superclass.name || "Object"

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      def module_names #: String
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end

      def enum_decls #: String?
        return unless klass.ancestors.include? ::ActiveHash::Enum

        <<~RBS
          include ActiveHash::Enum
          extend ActiveHash::Enum::Methods

          #{constants.map { |c| "#{c}: #{klass_name}" }.join("\n")}
        RBS
      end

      def constants #: Array[String]
        enum_accessors = klass.instance_eval { @enum_accessors }
        return [] unless enum_accessors

        klass.data.filter_map do |record|
          constant = enum_accessors.map { |name| record[name] }.join("_")
          next if constant.empty?

          constant.gsub!(/\W+/, "_")
          constant.gsub!(/^_|_$/, "")
          constant.upcase!
          constant
        end
      end

      def scope_decls #: String?
        return if parser.scopes.empty?

        parser.scopes.map do |scope_id, args|
          arguments = args.map { |arg| "untyped #{arg}" }.join(", ")
          <<~RBS.strip
            def self.#{scope_id}: (#{arguments}) -> ActiveHash::Relation[instance]
          RBS
        end.join("\n")
      end

      def association_decls #: String?
        return unless klass.ancestors.include? ::ActiveHash::Associations

        <<~RBS
          include ActiveHash::Associations
          extend ActiveHash::Associations::Methods

          #{has_many_decls(parser.has_many)}
          #{has_one_decls(parser.has_one)}
          #{belongs_to_decls(parser.belongs_to)}
        RBS
      end

      # @rbs definitions: Array[[Symbol, Hash[untyped, untyped]]]
      def has_many_decls(definitions) #: String # rubocop:disable Naming/PredicateName
        definitions.map do |definition|
          association_id, options = definition
          klass = options.fetch(:class_name, association_id.to_s.classify).constantize

          relation = if Object.const_defined?(:ActiveRecord) && klass.ancestors.include?(ActiveRecord::Base)
                       "#{klass.name}::ActiveRecord_Relation"
                     else
                       "Array[#{klass.name}]"
                     end

          <<~RBS
            def #{association_id}: () -> #{relation}
            def #{association_id.to_s.underscore.singularize}_ids: () -> Array[Integer]
          RBS
        end.join("\n")
      end

      # @rbs definitions: Array[[Symbol, Hash[untyped, untyped]]]
      def has_one_decls(definitions) #: String # rubocop:disable Naming/PredicateName
        definitions.map do |definition|
          association_id, options = definition
          class_name = options.fetch(:class_name, association_id.to_s.classify).constantize

          "def #{association_id}: () -> #{class_name}"
        end.join("\n")
      end

      # @rbs definitions: Array[[Symbol, Hash[untyped, untyped]]]
      def belongs_to_decls(definitions) #: String
        definitions.map do |definition|
          association_id, options = definition
          class_name = options.fetch(:class_name, association_id.to_s.classify).constantize

          <<~RBS
            def #{association_id}: () -> #{class_name}
            def #{association_id}=: (Integer) -> Integer
          RBS
        end.join("\n")
      end

      def method_decls #: String
        method_names.map do |method|
          method_type = stringify_type(method_types.fetch(method, "untyped"))
          if method == :id
            "def self.find: (#{method_type} id) -> instance | ...\n"
          else
            <<~RBS
              def #{method}: () -> #{method_type}
              def #{method}=: (#{method_type} value) -> #{method_type}
              def #{method}?: () -> bool
              def self.find_by_#{method}: (#{method_type} value) -> instance?
              def self.find_all_by_#{method}: (#{method_type} value) -> Array[instance]
            RBS
          end
        end.join("\n")
      end

      def method_names #: Array[Symbol]
        method_names = (klass.data || []).flat_map do |record|
          record.symbolize_keys.keys
        end
        method_names.uniq.select { |k| valid_field_name?(k) }
      end

      def method_types #: Hash[Symbol, untyped]
        method_types = Hash.new { |hash, key| hash[key] = [] } # steep:ignore
        (klass.data || []).each do |record|
          record.symbolize_keys.each do |key, value|
            method_types[key] << identify_class(value) # steep:ignore
          end
        end
        method_types.transform_values(&:uniq)
      end

      # @rbs name: String | Symbol
      def valid_field_name?(name) #: boolish
        name.to_s =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
      end

      def footer #: String
        "end\n" * klass.module_parents.size
      end

      # @rbs obj: untyped
      def identify_class(obj) #: String | singleton(Class)
        case obj
        when Array
          args = obj.map(&:class)
          "#{obj.class}[#{stringify_type(args)}]"
        when Hash
          keys = obj.keys.map(&:class)
          values = obj.values.map(&:class)
          "#{obj.class}[#{stringify_type(keys)}, #{stringify_type(values)}]"
        else
          obj.class
        end
      end

      # @rbs type: untyped
      def stringify_type(type) #: String
        if [TrueClass, FalseClass].include?(type)
          "bool"
        elsif type == NilClass
          "nil"
        elsif type.is_a? Class
          type.name.to_s
        elsif type.is_a? Array
          types = type.map { |t| stringify_type(t) }.uniq.sort
          if types.delete("nil")
            "(#{types.join(" | ")})?"
          else
            "(#{types.join(" | ")})"
          end
        else
          type.to_s
        end
      end
    end
  end
end
