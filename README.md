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

## TODO

- Basic validations (presence, range, numericality)
- Enum setting type
