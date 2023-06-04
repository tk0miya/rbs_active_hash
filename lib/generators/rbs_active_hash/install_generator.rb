# frozen_string_literal: true

require "rails"

module RbsActiveHash
  class InstallGenerator < Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_active_hash.rake", <<~RUBY
        begin
          require 'rbs_active_hash/rake_task'

          RbsActiveHash::RakeTask.new
        rescue LoadError
          # failed to load rbs_rails. Skip to load rbs_rails tasks.
        end
      RUBY
    end
  end
end
