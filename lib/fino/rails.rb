# frozen_string_literal: true

require "fino"

module Fino
  module Rails
    module RequestScopedCache
      autoload :Store, "fino/rails/request_scoped_cache/store"
      autoload :Pipe, "fino/rails/request_scoped_cache/pipe"
      autoload :Middleware, "fino/rails/request_scoped_cache/middleware"
    end
  end
end

require "fino/rails/engine"
