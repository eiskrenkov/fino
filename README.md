# Fino

Fino is plug & play distributed settings engine for Ruby and Rails

- Blazing fast reads with multiple adapers (Redis, Active Record)
- Out of the box UI
- A/B test and override settings on the go

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

# Overrides
Fino.enabled?(:maintenance_mode, for: "qa") #=> false

Fino.enable(:maintenance_mode, for: "qa")
Fino.enabled?(:maintenance_mode, for: "qa") #=> true

Fino.disable(:maintenance_mode, for: "qa")
Fino.enabled?(:maintenance_mode, for: "qa") #=> false
```

### Select setting

The simplest way to define select setting in fino is the following

```ruby
Fino.configure do
  # ...
  section :storefront, label: "Storefront" do
    setting :purchase_button_color,
            :select,
            options: [
              Fino::Settings::Select::Option.new(label: "Red", value: "red"),
              Fino::Settings::Select::Option.new(label: "Blue", value: "blue")
            ],
            default: "red",
            description: "Color of the purchase button"
  end
  # ...
end
```

Options must be an array of `Fino::Settings::Select::Option` instances

Then you can interact with the setting like that

```ruby
# Read selected option
selected_option = Fino.value(:purchase_button_color, at: :storefront)
# => #<Fino::Settings::Select::Option:0x0000000124fecd90 @label="Red", @metadata={}, @value="red">

# Read setting value
selected_option.value
# => "red"

# Read options
Fino.setting(:purchase_button_color, at: :storefront).options
# => [#<Fino::Settings::Select::Option:0x0000000124fecd90 @label="Red", @metadata={}, @value="red">,
      #<Fino::Settings::Select::Option:0x0000000124fecca0 @label="Blue", @metadata={}, @value="blue">]
```

#### Dynamic option

Options can also be defined dynamically using any callable object. Let's take a look at dynamic options in an example
of LLM model setting using [RubyLLM](https://github.com/crmne/ruby_llm) by @crmne

To define dynamic select options, use `:select` as setting type and provide a callable to `options`. Your object's
`call` method might be called with `refresh` option which is true only when user initiates options refresh manually.
This is useful for updating models list in RubyLLM for example

```ruby
section :llm, label: "LLM" do
  setting :model,
          :select,
          options: proc { |refresh:|
            RubyLLM.models.refresh! if refresh
            models = RubyLLM.models.chat_models

            openai_models = models.by_provider(:openai)
            anthropic_models = models.by_provider(:anthropic)

            build_pricing_label = proc do |model|
              text_pricing = model.pricing&.text_tokens
              next unless text_pricing && text_pricing.input && text_pricing.output

              "$#{text_pricing.input} / $#{text_pricing.output} per 1M tokens"
            end

            [*openai_models, *anthropic_models].map do |model|
              Fino::Settings::Select::Option.new(
                label: model.name,
                value: model.id,
                metadata: {
                  provider: model.provider_class.name,
                  pricing: build_pricing_label.call(model)
                }.compact
              )
            end
          },
          default: "gpt-5",
          description: "Chat model for AI-powered features"
  end
end
```

```ruby
# Read selected option
selected_option = Fino.setting(:model, at: :llm).value
# => #<Fino::Settings::Select::Option:0x0000000126257728
#     @label="GPT-4",
#     @metadata={provider: "OpenAI", pricing: "$30 / $60 per 1M tokens"},
#     @value="gpt-4">

# Read setting value
selected_option.value
# => "gpt-4"

# Read options
Fino.setting(:model, at: :llm).options
# => [#<Fino::Settings::Select::Option:0x000000012629e448
#      @label="GPT-5.3 Codex Spark",
#      @metadata={provider: "OpenAI", pricing: "$1.75 / $14 per 1M tokens"},
#      @value="gpt-5.3-codex-spark">,
#     #<Fino::Settings::Select::Option:0x000000012629e1c8
#      @label="GPT-5.4",
#      @metadata={provider: "OpenAI", pricing: "$2.5 / $15 per 1M tokens"},
#      @value="gpt-5.4">, ...]

# Refresh options
Fino.setting(:model, at: :llm).refresh!
# I, [2026-03-22T18:23:13.615270 #67293]  INFO -- RubyLLM: Fetching models from providers:
# I, [2026-03-22T18:23:13.615934 #67293]  INFO -- RubyLLM: Fetching models from models.dev API...
```

#### Use with RubyLLM

```ruby
chat = RubyLLM.chat(model: Fino.setting(:model, at: :llm).value)
chat.ask "Why Ruby?"
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

#### Experiment analysis

Fino adapters might support A/B testing analysis, both built-in `solid` and `redis` adapters do

When you run an A/B test for a setting, fino automatically calculates variant based on a stable identifier you pass as
a `for` option

```ruby
Fino.set(model: "gpt-5", at: :openai, variants: { 20.0 => "gpt-6" })

Fino.value(:model, at: :openai, for: "user_1") #=> "gpt-6"
Fino.value(:model, at: :openai, for: "user_1") #=> "gpt-6"

Fino.value(:model, at: :openai, for: "user_2") #=> "gpt-5"
```

Later in your code, when user performs a "desired" action, simply call

```ruby
Fino.convert!(:model, at: :openai, for: "user_2")
```

to record a "convertion" for `user_2`. As Fino knows the right variant for `user_2`, conversion will be counted
todards it. Thanks to that later you'll be able to call

```ruby
Fino.analyse(:model, at: :openai)
```

to receive a detailed report over variants performance. Also bar charts comparing all variants and a chart displaying
amount of conversions over time per variant will be accessible on UI with `fino-rails`

To reset analysis data for an experiment:

```ruby
Fino.reset_analysis!(:model, at: :openai)
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

### Callbacks

Fino provides callbacks configuration that will be called once some particular action is triggered:

- `after_write` - yields `setting_definition`, `value`, `overrides` and `variants`, is triggered when setting is updated

```ruby
Fino.configure do
  # ...

  after_write do |setting_definition, value, overrides, variants|
    next unless setting_definition.tags.include?(:monitor)

    Monitor.track_changes("Set #{setting_definition.key} to #{value}")
  end

  settings do
    setting :maintenance_mode, :boolean, default: false

    setting :http_read_timeout, :integer, unit: :ms, default: 200, tags: %i[monitor]
    setting :http_open_timeout, :integer, unit: :ms, default: 500, tags: %i[monitor]
  end
end
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

## Development

To create and mugrate dummy app db to test solid adapter, do

```bash
cd spec/dummy && bin/rails db:create db:migrate
```

## Releasing

`rake release`

## Contributing

1. Fork it
2. Do contribution
6. Create Pull Request into this repo
