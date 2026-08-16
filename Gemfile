# frozen_string_literal: true

source "https://rubygems.org", cooldown: 7

# Specify your gem's dependencies in rbs_active_hash.gemspec
gemspec

gem "rake", "~> 13.4"

gem "rubocop", "~> 1.89"
gem "rubocop-numbered-params"
gem "rubocop-rake"
gem "rubocop-rbs_inline"
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
