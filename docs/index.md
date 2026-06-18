---
layout: home
hero:
  name: Fino
  text: Plug & play distributed settings engine
  tagline: For Ruby & Rails
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started/quickstart
    - theme: alt
      text: Live Demo
      link: https://fino.iskrenkov.me/fino
    - theme: alt
      text: GitHub
      link: https://github.com/eiskrenkov/fino
features:
  - icon: "\U0001F680"
    title: No deploys needed
    details: Feature toggles, per-user overrides and A/B tests - change anything at runtime without shipping code
  - icon: "\U0001F9EA"
    title: A/B testing built in
    details: Sticky variants, conversion tracking and experiment analysis. No third-party platform required
  - icon: "\U0001F3A8"
    title: Admin UI out of the box
    details: Mount one Rails engine, get a full settings dashboard with dark mode and live experiment charts
  - icon: "\U0001F50C"
    title: Plug any storage
    details: Redis for speed, Solid for simplicity. Swap adapters without touching application code
---

# Quick start

Install gems

```bash
bundle add fino fino-solid fino-rails
bundle install
```

Create basic configuration file

```ruby
# config/initializers/fino.rb

require "fino-redis"

Fino.configure do
  adapter { Fino::Solid::Adapter.new }

  settings do
    setting :maintenance_mode, :boolean, default: false
  end
end
```

Interact with settings

```ruby
Fino.value(:maintenance_mode) # => false
Fino.set(maintenance_mode: true)
Fino.value(:maintenance_mode) # => true
```
