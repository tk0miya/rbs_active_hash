# frozen_string_literal: true

require "rbs"
require "rbs_rails/util"
require "active_hash"

module RbsActiveHash
  module ActiveHash
    def self.user_defined_model?(klass)
      klass.name !~ /^Active(Hash|File|JSON|Yaml)::/
    end

    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      attr_reader :klass, :klass_name

      def initialize(klass)
        @klass = klass
        @klass_name = RbsRails::Util.module_name(klass)
      end

      def generate
        if klass.ancestors.include? ::ActiveFile::Base
          begin
            klass.reload
          rescue StandardError
            nil
          end
        end

        RbsRails::Util.format_rbs klass_decl
      end

      private

      def klass_decl
        <<~RBS
          #{header}
          #{enum_decls}
          #{method_decls}
          #{footer}
        RBS
      end

      def header
        namespace = +""
        klass_name.split("::").map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = RbsRails::Util.module_name(superclass)

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      def module_names
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end

      def enum_decls
        return unless klass.ancestors.include? ::ActiveHash::Enum

        <<~RBS
          include ActiveHash::Enum
          extend ActiveHash::Enum::Methods

          #{constants.map { |c| "#{c}: instance" }.join("\n")}
        RBS
      end

      def constants
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

      def method_decls
        method_names.map do |method|
          method_type = stringify_type(method_types.fetch(method, "untyped"))
          <<~RBS
            def #{method}: () -> #{method_type}
            def #{method}=: (#{method_type} value) -> #{method_type}
            def #{method}?: () -> bool
            def self.find_by_#{method}: (#{method_type} value) -> self?
            def self.find_all_by_#{method}: (#{method_type} value) -> Array[self]
          RBS
        end.join("\n")
      end

      def method_names
        method_names = (klass.data || []).flat_map do |record|
          record.symbolize_keys.keys
        end
        method_names.uniq.select { |k| k != :id && valid_field_name?(k) }
      end

      def method_types
        method_types = Hash.new { |hash, key| hash[key] = [] }
        (klass.data || []).each do |record|
          record.symbolize_keys.each do |key, value|
            method_types[key] << value.class
          end
        end
        method_types.transform_values(&:uniq)
      end

      def valid_field_name?(name)
        name.to_s =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
      end

      def footer
        "end\n" * klass.module_parents.size
      end

      def stringify_type(type)
        if [TrueClass, FalseClass].include?(type)
          "bool"
        elsif type == NilClass
          "nil"
        elsif type.is_a? Class
          type.name
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
