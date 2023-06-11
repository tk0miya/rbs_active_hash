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
      def initialize(klass)
        @klass = klass
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
        module_defs = module_names.map { |module_name| "module #{module_name}" }

        class_name = klass.name.split("::").last
        class_def = "class #{class_name} < ::#{klass.superclass}"

        (module_defs + [class_def]).join("\n")
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
          <<~RBS
            def #{method}: () -> untyped
            def #{method}=: (untyped value) -> void
            def #{method}?: () -> bool
            def self.find_by_#{method}: (untyped value) -> self?
            def self.find_all_by_#{method}: (untyped value) -> Array[self]
          RBS
        end.join("\n")
      end

      def method_names
        method_names = (klass.data || []).flat_map do |record|
          record.symbolize_keys.keys
        end
        method_names.uniq.select { |k| k != :id && valid_field_name?(k) }
      end

      def valid_field_name?(name)
        name.to_s =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
      end

      def footer
        "end\n" * klass.module_parents.size
      end

      attr_reader :klass
    end
  end
end
