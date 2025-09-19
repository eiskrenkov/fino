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

    section :openai, label: "OpenAI" do
      setting :model,
              :string,
              default: "gpt-4o",
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
      setting :http_read_timeout, :integer, default: 200 # in ms
      setting :http_open_timeout, :integer, default: 100 # in ms
    end
  end
end
```

### Work with settings

```ruby
Fino.value(:model, at: :openai) #=> "gpt-4o"
Fino.value(:temperature, at: :openai) #=> 0.7

Fino.values(:model, :temperature, at: :openai) #=> ["gpt-4", 0.7]

Fino.set(model: "gpt-5", at: :openai)
Fino.value(:model, at: :openai) #=> "gpt-5"
```

## Overrides

```ruby
Fino.value(:model, at: :openai) #=> "gpt-4o"

Fino.set(model: "gpt-5", at: :openai, overrides: { "qa" => "our_local_model_not_to_pay_to_sam_altman" })

Fino.value(:model, at: :openai) #=> "gpt-5"
Fino.value(:model, at: :openai, for: "qa") #=> "our_local_model_not_to_pay_to_sam_altman"
```

## A/B testing

```ruby
Fino.value(:model, at: :openai) #=> "gpt-4o"

# "gpt-5" becomes the control variant value and a 20.0% variant is created with value "gpt-6"
Fino.set(model: "gpt-5", at: :openai, variants: { 20.0 => "gpt-6" })

Fino.variant(:model, at: :openai, for: "user_1") #=> #<struct Fino::Variant percentage=20.0, value="gpt-6">

# Picked variant is sticked to the user
Fino.value(:model, at: :openai, for: "user_1") #=> "gpt-6"
Fino.value(:model, at: :openai, for: "user_1") #=> "gpt-6"

Fino.value(:model, at: :openai, for: "user_2") #=> "gpt-5"
```

### Manage settings via UI

```ruby
gem "fino-rails"
```

Mount Fino Rails engine in your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Fino::Rails::Engine, at: "/fino"
end
```

<img width="1229" height="641" alt="Screenshot 2025-09-04 at 16 01 51" src="https://github.com/user-attachments/assets/646df84c-c25b-4890-9637-c481e18c9bd4" />
