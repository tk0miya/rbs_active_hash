# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in rbs_active_hash.gemspec
gemspec

gem "rake", "~> 13.3"

gem "rubocop", "~> 1.81"
gem "rubocop-rake"
gem "rubocop-rspec"

group :test do
  gem "activerecord"
end

group :development do
  gem "rspec", require: false
  gem "rspec-daemon", require: false

  gem "rbs-inline", require: false
  gem "steep"
end

# dependencies only for signature
group :signature do
  gem "railties"
end
