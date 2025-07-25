# frozen_string_literal: true

require 'casein'
require 'rails'
require 'bootstrap'
require 'jquery-rails'

module Casein
  class Engine < Rails::Engine
    initializer 'casein.assets.precompile' do |app|
      app.config.assets.precompile += %w[casein/login.css casein/casein.css casein/casein.js casein/html5shiv.js casein/custom.css casein/custom.js casein/auth_custom.css casein/auth_custom.js casein/*.png]
    end

    rake_tasks do
      load 'railties/tasks.rake'
    end

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end
  end

  class RouteConstraint
    def matches?(request)
      return false if request.fullpath.include?('/casein')
      return false if request.fullpath.include?('/admin')

      true
    end
   end
end
