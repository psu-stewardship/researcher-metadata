source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4'

# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'

# Use Puma as the app server
gem 'puma', '~> 5.3'

# Use SCSS for stylesheets
gem 'sass-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Notify the team of any exceptions
gem 'bugsnag'

# Simple, efficient CSV processing for Ruby
gem 'smarter_csv'

# Library for bulk inserting data using ActiveRecord
gem 'activerecord-import'

# The ultimate text progress bar library for Ruby
gem 'progressbar'

# RailsAdmin is a Rails engine that provides an easy-to-use interface for managing your data
gem "rails_admin", "~> 1.4"

gem 'rails_admin_toggleable'

# Authentication framework
gem 'devise', '~> 4.8'

# Support for Penn State Azure Active Directory authentication
gem 'omniauth', '~> 2.0'
gem 'omniauth-oauth2', '~> 1.7'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

# Authorization framework
gem 'cancancan', '~> 2.0'

# A lightning fast JSON:API serializer for Ruby Objects
gem 'fast_jsonapi'

# Swagger::Blocks is a DSL for pure Ruby code blocks that can be turned into JSON
gem 'swagger-blocks'

# Include swagger-ui as a Raile engine
gem 'swagger_ui_engine'

# A Material Design theme for rails_admin
gem 'rails_admin_material'

# Bootstrap 4 ruby gem for Ruby on Rails
gem 'bootstrap'

# jQuery for Rails
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Foundation for Rails
gem 'foundation-rails'

# HTTP client
gem 'httparty'

# UI Icons
gem 'font-awesome-rails'

# Lightweight Directory Access Protocol client
gem 'net-ldap'

# JSON parser wrapper
gem 'multi_json'

# HTML Form builder
gem 'simple_form'

# Build nested HTML forms
gem 'cocoon'

# Harvest metadata from OAI-PMH repositories
gem 'fieldhand', '~> 0.12'

# ScholarSphere API HTTP client for depositing works on behalf of users
gem 'scholarsphere-client', '~> 0.3'

# File uploading
gem 'carrierwave'

# For running async jobs
gem 'delayed_job_active_record'

# For running delayed_job daemon (or other processes)
gem 'daemons'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  # Default test framework
  gem 'rspec-rails'

  # Generate fake test data
  gem 'ffaker'

  # Automatically test your rails API against its OpenAPI (Swagger) description
  # of end-points, models, and query parameters
  gem 'apivore'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'spring-commands-rspec'

  # Deploy to multiple environments
  gem 'capistrano-ext'

  # Useful recipes for generalizing deployment behavior
  gem 'capistrano-helpers'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15', '< 4.0'

  # PhantomJS driver for capybara
  gem 'poltergeist'

  # Clean out database between test runs
  gem 'database_cleaner'

  # See what your headless browser is seeing with save_and_open_page
  gem 'launchy'

  # Fancy rspec matchers for rails
  gem 'shoulda-matchers', git: "https://github.com/thoughtbot/shoulda-matchers", require: false

  # Test object factory
  gem 'factory_bot_rails'

  # Integration test helpers for mailers
  gem 'capybara-email'

  # Extracted test matchers for rails controllers
  gem 'rails-controller-testing'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
