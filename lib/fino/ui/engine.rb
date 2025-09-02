# frozen_string_literal: true

require "fino-ui"

class Fino::UI::Engine < Rails::Engine
  isolate_namespace Fino::UI

  paths["app"] << root.join("lib", "fino", "ui", "app")
  paths["config/initializers"] << root.join("lib", "fino", "ui", "config", "initializers")

  initializer "fino.ui.load_routes", before: :add_routing_paths do |app|
    custom_routes = root.join("lib", "fino", "ui", "config", "routes.rb")
    app.routes_reloader.paths << custom_routes.to_s
  end
end
