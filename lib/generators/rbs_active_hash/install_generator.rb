# frozen_string_literal: true

require "rails"

module RbsActiveHash
  class InstallGenerator < Rails::Generators::Base
    def create_raketask #: void
      create_file "lib/tasks/rbs_active_hash.rake", <<~RUBY
        # frozen_string_literal: true

        begin
          require "rbs_active_hash/rake_task"

          RbsActiveHash::RakeTask.new
        rescue LoadError
          # failed to load rbs_active_hash. Skip to load rbs_active_hash tasks.
        end
      RUBY
    end
  end
end
