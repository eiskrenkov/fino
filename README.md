# Fino

⚠️ Fino is under active development. API changes are possible ⚠️

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
Fino.value(:model, :openai) #=> "gpt-4o"
Fino.value(:temperature, :openai) #=> 0.7

Fino.set("gpt-5", :model, :openai)
Fino.value(:model, :openai) #=> "gpt-5"
```

### Manage settings via UI

```ruby
gem "fino-ui"
```

Mount Fino UI in your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Fino::UI::Engine, at: "/fino"
end
```

<img width="1229" height="641" alt="Screenshot 2025-09-04 at 16 01 51" src="https://github.com/user-attachments/assets/646df84c-c25b-4890-9637-c481e18c9bd4" />

## TODO

- Preloading settings to be able to fetch all of them in one adapter call
- Request scoped memoization when integrating with Rails
- Nicer UI
- Basic validations (presence, range, numericality)
- Enum setting type
