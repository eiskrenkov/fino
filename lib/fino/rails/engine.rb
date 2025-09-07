# frozen_string_literal: true

class Fino::Rails::Engine < ::Rails::Engine
  isolate_namespace Fino::Rails

  #
  # Engine
  #

  paths["app"] << root.join("lib", "fino", "rails", "app")
  paths["config/initializers"] << root.join("lib", "fino", "rails", "config", "initializers")

  initializer "fino.rails.engine.views" do |_app|
    ActiveSupport.on_load :action_controller do
      prepend_view_path Fino::Rails::Engine.root.join("lib", "fino", "rails", "app", "views")
    end
  end

  initializer "fino.rails.engine.routes", before: :add_routing_paths do |app|
    custom_routes = root.join("lib", "fino", "rails", "config", "routes.rb")
    app.routes_reloader.paths << custom_routes.to_s
  end

  #
  # Request scoped cache
  #

  initializer "fino.pipeline" do
    Fino.configure do
      pipeline do
        prepend Fino::Rails::RequestScopedCache::Pipe.new
      end
    end
  end

  initializer "fino.middleware" do |app|
    app.middleware.use Fino::Rails::RequestScopedCache::Middleware
  end
end
