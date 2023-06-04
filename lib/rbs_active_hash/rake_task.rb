# frozen_string_literal: true

require "pathname"
require "rake"
require "rake/tasklib"
require "rbs_active_hash"

module RbsActiveHash
  class RakeTask < Rake::TaskLib
    attr_accessor  :name, :signature_root_dir

    def initialize(name = :"rbs:active_hash", &block)
      super()

      @name = name

      block&.call(self)

      setup_signature_root_dir!

      define_clean_task
      define_generate_task
      define_setup_task
    end

    def define_setup_task
      desc "Run all tasks of rbs_active_hash"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup": deps)
    end

    def define_clean_task
      desc "Clean up generated RBS files"
      task("#{name}:clean": :environment) do
        sh "rm", "-rf", @signature_root_dir.to_s
      end
    end

    def define_generate_task
      desc "Generate RBS files for ActiveHash models"
      task("#{name}:generate": :environment) do
        Rails.application.eager_load!

        ::ActiveHash::Base.descendants.each do |klass|
          next unless RbsActiveHash::ActiveHash.user_defined_model?(klass)

          path = signature_root_dir / "app/models/#{klass.name.underscore}.rbs"
          path.dirname.mkpath
          path.write RbsActiveHash::ActiveHash.class_to_rbs(klass)
        end
      end
    end

    private

    def setup_signature_root_dir!
      @signature_root_dir ||= Pathname(Rails.root / "sig/active_hash")
      @signature_root_dir.mkpath
      @signature_root_dir
    end
  end
end
