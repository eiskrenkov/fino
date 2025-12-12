# frozen_string_literal: true

require "fino"

module Fino
  module Rails
    module Preloading
      autoload :Middleware, "fino/rails/preloading/middleware"
    end

    module RequestScopedCache
      autoload :Pipe, "fino/rails/request_scoped_cache/pipe"
      autoload :Middleware, "fino/rails/request_scoped_cache/middleware"
      autoload :Store, "fino/rails/request_scoped_cache/store"
    end

    autoload :Instrumentation, "fino/rails/instrumentation"

    module Instrumentation
      autoload :Adapter, "fino/rails/instrumentation/adapter"
      autoload :Cache, "fino/rails/instrumentation/cache"
    end
  end

  module_function

  def root
    File.expand_path("rails", __dir__)
  end
end

require "fino/rails/engine"
require "fino/rails/generators/install/install_generator"
