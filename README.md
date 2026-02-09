# Fino

⚠️ Fino in active development phase at wasn't properly battle tested in production just yet. Give us a star and stay tuned for Production test results and new features

Fino is a dynamic settings engine for Ruby and Rails

## Usage

### Define settings via DSL

```ruby
require "fino-redis"

Fino.configure do
  adapter do
    Fino::Redis::Adapter.new(
      Redis.new(**Rails.application.config_for(:redis))
    )
  end

  cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }

  settings do
    setting :maintenance_mode, :boolean, default: false

    setting :api_rate_limit,
            :integer,
            default: 1000,
            description: "Maximum API requests per minute per user to prevent abuse"

    section :openai, label: "OpenAI" do
      setting :model,
              :string,
              default: "gpt-5",
              description: "OpenAI model"

      setting :temperature,
              :float,
              default: 0.7,
              description: "Model temperature"
    end

    section :feature_toggles, label: "Feature Toggles" do
      setting :new_ui, :boolean, default: true
      setting :beta_functionality, :boolean, default: false
    end

    section :my_micro_service, label: "My Micro Service" do
      setting :http_read_timeout, :integer, unit: :ms, default: 200
      setting :http_open_timeout, :integer, unit: :ms, default: 100
    end
  end
end
```

### Work with settings

```ruby
Fino.value(:model, at: :openai) #=> "gpt-5"
Fino.value(:temperature, at: :openai) #=> 0.7

Fino.values(:model, :temperature, at: :openai) #=> ["gpt-4", 0.7]

Fino.set(model: "gpt-5", at: :openai)
Fino.value(:model, at: :openai) #=> "gpt-5"
```

### Feature toggles

```ruby
Fino.enabled?(:maintenance_mode) #=> false
Fino.disabled?(:maintenance_mode) #=> true

Fino.enabled?(:maintenance_mode, for: "qa") #=> false
Fino.add_override(:maintenance_mode, "qa" => true)
Fino.enabled?(:maintenance_mode, for: "qa") #=> true
```

### Overrides

```ruby
Fino.value(:model, at: :openai) #=> "gpt-5"

Fino.set(model: "gpt-5", at: :openai, overrides: { "qa" => "our_local_model_not_to_pay_to_sam_altman" })

Fino.value(:model, at: :openai) #=> "gpt-5"
Fino.value(:model, at: :openai, for: "qa") #=> "our_local_model_not_to_pay_to_sam_altman"

Fino.setting(:model, at: :openai).overrides #=> { "qa" => "our_local_model_not_to_pay_to_sam_altman" }

Fino.add_override(:model, at: :openai, "admin" => "gpt-2000")
Fino.setting(:model, at: :openai).overrides #=> { "qa" => "our_local_model_not_to_pay_to_sam_altman", "admin" => "gpt-2000" }
```

### A/B testing

```ruby
Fino.value(:model, at: :openai) #=> "gpt-5"

# "gpt-5" becomes the control variant value and a 20.0% variant is created with value "gpt-6"
Fino.set(model: "gpt-5", at: :openai, variants: { 20.0 => "gpt-6" })

Fino.setting(:model, at: :openai).experiment.variant(for: "user_1") #=> #<Fino::AbTesting::Variant percentage: 20.0, value: "gpt-6">

# Picked variant is sticked to the user
Fino.value(:model, at: :openai, for: "user_1") #=> "gpt-6"
Fino.value(:model, at: :openai, for: "user_1") #=> "gpt-6"

Fino.value(:model, at: :openai, for: "user_2") #=> "gpt-5"
```

### Unit conversion

Fino is able to convert numeric settings into various units

```ruby
Fino.configure do
  # ...

  settings do
    section :my_micro_service, label: "My Micro Service" do
      setting :http_read_timeout,
              :integer,
              unit: :ms, # When you define setting, specify unit (e.g ms/sec) to later be able to convert it
              default: 200
    end
  end
end

Fino.value(:http_read_timeout, at: :my_micro_service) #=> 200

# Convert from ms to sec on the fly
Fino.value(:http_read_timeout, at: :my_micro_service, unit: :sec) #=> 0.2
Fino.setting(:http_read_timeout, at: :my_micro_service).value(unit: :sec) #=> 0.2
```

## Rails integration

Fino easily integrates with Rails. Just add the gem to your Gemfile:

```
gem "fino-rails", require: false
```

to get built-in UI engine for your settings!

### UI engine

Mount Fino Rails engine in your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Fino::Rails::Engine, at: "/fino"
end
```

### Configuration

```ruby
Rails.application.configure do
  config.fino.instrument = true
  config.fino.log = true
  config.fino.cache_within_request = false
  config.fino.preload_before_request = true
end
```

<img width="1493" height="676" alt="Screenshot 2025-09-19 at 13 09 06" src="https://github.com/user-attachments/assets/19b6147a-e18c-41cf-aac7-99111efcc9d5" />

<img width="1775" height="845" alt="Screenshot 2025-09-19 at 13 09 33" src="https://github.com/user-attachments/assets/c0010abd-285d-43d0-ae5d-ce0edb781309" />

## Performance tweaks

1. In Memory cache

   Fino provides in-memory settings caching functionality which will store settings received from adaper in memory for
   a very quick access. As this kind of cache is not distributed between machines, but belongs to each process
   separately, it's impossible to invalidate all at once, so be aware that setting update application time will depend
   on cache TTL you configure

   ```ruby
   Fino.configure do
     # ...
     cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }
     # ...
   end
   ```

2. Request scoped cache

   When using Fino in Rails context it's possible to cache settings within request, in current thread storage. This is
   safe way to cache settings as it's lifetime is limited, thus it is enabled by default

   ```ruby
   Rails.application.configure do
     config.fino.cache_within_request = true
   end
   ```

3. Preloading

   In Rails context it is possible to tell Fino to preload multiple settings before processing request in a single
   adapter call. Preloading is recommended for requests that use multiple different settings in their logic

   ```ruby
   # Preload all settings
   Rails.application.configure do
     config.fino.preload_before_request = true
   end

   # Preload specific subset of settings depending on request
   Rails.application.configure do
     config.fino.preload_before_request = ->(request) {
       case request.path
       when "request/using/all/settings"
         true
       when "request/not/using/settings"
         false
       when "request/using/specific/settings"
         [
           :api_rate_limit,
           openai: [:model, :temperature]
         ]
       end
     }
   end
   ```

## Releasing

`rake release`

## Contributing

1. Fork it
2. Do contribution
6. Create Pull Request into this repo
