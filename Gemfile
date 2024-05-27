# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in rbs_active_hash.gemspec
gemspec

gem "rake", "~> 13.2"

gem "rubocop", "~> 1.64"

group :test do
  gem "activerecord"
end

group :development do
  gem "rspec", require: false
  gem "rspec-daemon", require: false

  gem "steep"
end

# dependencies only for signature
group :signature do
  gem "railties"
end
