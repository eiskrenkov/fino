# frozen_string_literal: true

require "fino"

module Fino
  module Rails
    module RequestScopedCache
      autoload :Pipe, "fino/rails/request_scoped_cache/pipe"
      autoload :Middleware, "fino/rails/request_scoped_cache/middleware"
    end

    module Instrumentation
      autoload :Pipe, "fino/rails/instrumentation/pipe"
    end
  end
end

require "fino/rails/engine"
