# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in rbs_active_hash.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rubocop", "~> 1.53"

group :development do
  gem "rspec", require: false
  gem "rspec-daemon", require: false

  gem "steep"
end

# dependencies only for signature
group :signature do
  gem "activerecord"
  gem "railties"
end
