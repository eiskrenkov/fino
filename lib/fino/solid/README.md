# Fino::Solid

ActiveRecord adapter for [Fino](https://github.com/eiskrenkov/fino) settings engine, inspired by solid_queue.

## Features

- **Database-backed persistence** using ActiveRecord
- **Efficient read performance** with single-table design
- **Multi-database support** (SQLite, PostgreSQL, MySQL)
- **Rails integration** with migration generators
- **Supports all Fino features**: overrides, A/B testing, sections
- **Thread-safe** and production-ready

## Installation

Add to your Gemfile:

```ruby
gem "fino-solid"
```

Then run:

```bash
bundle install
```

## Setup

### Rails Applications

1. Generate the migration:

```bash
bin/rails generate fino:solid:install
```

2. Run the migration:

```bash
bin/rails db:migrate
```

3. Configure Fino to use the Solid adapter:

```ruby
# config/initializers/fino.rb
require "fino-solid"

Fino.configure do
  adapter { Fino::Solid::Adapter.new }

  settings do
    setting :maintenance_mode, :boolean, default: false
    # ... your settings
  end
end
```

### Non-Rails Applications

1. Create the migration manually:

```ruby
class CreateFinoSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :fino_settings do |t|
      t.string :key, null: false
      t.text :data
      t.timestamps
    end

    add_index :fino_settings, :key, unique: true
  end
end
```

2. Configure the adapter:

```ruby
require "fino-solid"
require "active_record"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "db/fino.sqlite3"
)

Fino.configure do
  adapter { Fino::Solid::Adapter.new }

  settings do
    # ... your settings
  end
end
```

## Configuration

### Multi-Database Setup

If you're using Rails multi-database configuration (like solid_queue), you can configure Fino::Solid to use a specific database:

```ruby
# config/initializers/fino.rb
Fino::Solid.configure do
  self.connects_to = { database: { writing: :settings } }
end
```

Then configure your database.yml:

```yaml
production:
  primary:
    <<: *default
    database: my_app_production
  settings:
    <<: *default
    database: my_app_settings_production
    migrations_paths: db/settings_migrate
```

## Database Schema

The adapter uses a simple, efficient single-table design:

```ruby
create_table :fino_settings do |t|
  t.string :key, null: false      # "api_rate_limit" or "openai/model"
  t.text :data                    # JSON: {"v": "value", "s/scope/v": "override", ...}
  t.timestamps
end

add_index :fino_settings, :key, unique: true
```

### Data Structure

Settings are stored as JSON with this structure:

```json
{
  "v": "serialized_value",
  "s/qa/v": "override_for_qa_scope",
  "s/admin/v": "override_for_admin_scope",
  "v/20.0/v": "variant_value_for_20_percent",
  "v/30.0/v": "variant_value_for_30_percent"
}
```

This mirrors the Redis adapter structure for consistency.

## Performance

### Read Performance

- **Single setting**: 1 query (`SELECT * FROM fino_settings WHERE key = ?`)
- **Multiple settings**: 1 query (`SELECT * FROM fino_settings WHERE key IN (?, ?, ?)`)
- **All settings**: 1 query (`SELECT * FROM fino_settings`)

### Write Performance

- Uses ActiveRecord's `upsert` for atomic write operations
- Single transaction per setting update

### Optimization Tips

1. **Use in-memory cache** to reduce database queries:

```ruby
Fino.configure do
  adapter { Fino::Solid::Adapter.new }
  cache { Fino::Cache::Memory.new(expires_in: 3.seconds) }
end
```

2. **Batch reads** with `read_multi`:

```ruby
# In Rails:
Fino.values(:maintenance_mode, :api_rate_limit)  # 1 query instead of 2
```

3. **Preload settings** in Rails:

```ruby
Rails.application.configure do
  config.fino.preload_before_request = true
end
```

## Supported Databases

- **SQLite** 3.38+ (with JSON support)
- **PostgreSQL** 9.4+ (with JSON/JSONB)
- **MySQL** 5.7+ (with JSON support)

## Examples

### Basic Usage

```ruby
# Set a value
Fino.set(api_rate_limit: 1000)

# Read a value
Fino.value(:api_rate_limit)  # => 1000
```

### With Overrides

```ruby
# Set value with scope overrides
Fino.set(
  api_rate_limit: 1000,
  overrides: {
    "premium" => 5000,
    "enterprise" => 10000
  }
)

# Read with scope
Fino.value(:api_rate_limit)                    # => 1000
Fino.value(:api_rate_limit, for: "premium")    # => 5000
Fino.value(:api_rate_limit, for: "enterprise") # => 10000
```

### With A/B Testing

```ruby
# Create an experiment
Fino.set(
  api_rate_limit: 1000,
  variants: {
    20.0 => 2000,  # 20% of users get 2000
    30.0 => 3000   # 30% of users get 3000
  }
  # Remaining 50% get control value (1000)
)

# Users are deterministically assigned to variants
Fino.value(:api_rate_limit, for: "user_123")  # => 2000 (always same)
Fino.value(:api_rate_limit, for: "user_456")  # => 1000 (control)
```

## Comparison with Redis Adapter

| Feature | Fino::Solid | Fino::Redis |
|---------|-------------|-------------|
| Persistence | SQL Database | Redis |
| Read Performance | Excellent (indexed) | Excellent (in-memory) |
| Write Performance | Good (ACID) | Excellent |
| Durability | ACID compliant | Depends on Redis config |
| Multi-database | Native support | Namespace support |
| Backup/Restore | Standard DB tools | Redis tools |
| Query Flexibility | SQL available | Limited |
| Setup Complexity | Low (Rails) | Medium |

## Testing

The gem includes comprehensive integration tests using shared examples:

```bash
# Run Solid adapter tests
bundle exec rspec spec/integration/solid_adapter_spec.rb

# Test all databases
DATABASE=sqlite bundle exec rspec spec/integration/solid_adapter_spec.rb
DATABASE=postgresql bundle exec rspec spec/integration/solid_adapter_spec.rb
DATABASE=mysql bundle exec rspec spec/integration/solid_adapter_spec.rb
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT
