# frozen_string_literal: true

require "fino-ui"

class Fino::UI::Engine < Rails::Engine
  isolate_namespace Fino::UI

  paths["app"] << root.join("lib", "fino", "ui", "app")
  paths["config/initializers"] << root.join("lib", "fino", "ui", "config", "initializers")

  initializer "fino.ui.append_view_paths" do |_app|
    ActiveSupport.on_load :action_controller do
      prepend_view_path Fino::UI::Engine.root.join("lib", "fino", "ui", "app", "views")
    end
  end

  initializer "fino.ui.load_routes", before: :add_routing_paths do |app|
    custom_routes = root.join("lib", "fino", "ui", "config", "routes.rb")
    app.routes_reloader.paths << custom_routes.to_s
  end
end
