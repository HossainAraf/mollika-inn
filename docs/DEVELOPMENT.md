# Mollika Inn — Development Guide

## Getting Started

See [SETUP.md](SETUP.md) for initial installation. This document covers day-to-day development workflows.

---

## Running the App

```bash
bundle exec rails server -b 0.0.0.0 -p 5000
```

On Replit, just press the **Run** button — it executes the `Start application` workflow.

---

## Console

```bash
bundle exec rails console
```

Useful one-liners:

```ruby
# Check bookings
Booking.count
Booking.includes(:guest).pending

# Check a setting
Setting["site_name"]
Setting["site_phone"] = "+880 1712 000000"

# Re-seed demo data
load Rails.root.join("db/seeds.rb")
```

---

## Database Migrations

### Create a new migration

```bash
bundle exec rails generate migration AddNoteToRooms note:text
bundle exec rails db:migrate
```

### Rollback

```bash
bundle exec rails db:rollback           # one step back
bundle exec rails db:rollback STEP=3    # three steps back
```

### Custom `mollika` Schema

All tables use the `mollika` PostgreSQL schema. Migrations that create tables use:

```ruby
create_table "mollika.table_name" do |t|
  # ...
end
```

If you use `create_table :name` without the schema prefix, the table lands in `public` and won't be found. The schema search path in `database.yml` (`mollika, public`) handles reads but not initial table creation.

---

## Adding a New Admin Section

### 1. Generate the migration

```bash
bundle exec rails generate migration CreateMyThings name:string ...
bundle exec rails db:migrate
```

### 2. Create the model

```ruby
# app/models/my_thing.rb
class MyThing < ApplicationRecord
  validates :name, presence: true
end
```

### 3. Create the controller (inherit from `Admin::BaseController`)

```ruby
# app/controllers/admin/my_things_controller.rb
class Admin::MyThingsController < Admin::BaseController
  def index
    @my_things = MyThing.all
  end
  # ...
end
```

### 4. Add routes

```ruby
# config/routes.rb — inside the `namespace :admin` block
resources :my_things
```

### 5. Create views in `app/views/admin/my_things/`

---

## Adding a New Public Page

### 1. Controller

```ruby
# app/controllers/my_page_controller.rb
class MyPageController < ApplicationController
  skip_before_action :require_authentication  # public controllers skip auth automatically
  def index; end
end
```

`ApplicationController` is public by default — no `skip_before_action` needed unless you explicitly added auth to it.

### 2. Route

```ruby
# config/routes.rb
get "/my-page", to: "my_page#index"
```

### 3. View in `app/views/my_page/index.html.erb`

---

## Stimulus Controllers (JavaScript)

Stimulus controllers live in `app/javascript/controllers/`. They are auto-registered via importmap.

```javascript
// app/javascript/controllers/my_feature_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  connect() {
    console.log("connected!")
  }
}
```

In the view:
```html
<div data-controller="my-feature">
  <span data-my-feature-target="output"></span>
</div>
```

---

## Turbo-Compatible Links for Non-GET Requests

Rails 7+ with Turbo requires `data: { turbo_method: :patch }` instead of the old `method: :patch`:

```erb
<%# CORRECT — Turbo-compatible %>
<%= link_to "Confirm", confirm_admin_booking_path(@booking),
    data: { turbo_method: :patch, turbo_confirm: "Are you sure?" } %>

<%# WRONG — does not work with Turbo %>
<%= link_to "Confirm", confirm_admin_booking_path(@booking), method: :patch %>
```

For DELETE actions, use `button_to` with `method: :delete` (renders a form) or `data: { turbo_method: :delete }` on a link.

---

## Helpers

### `status_badge_class(status)` — `ApplicationHelper`

Returns a Tailwind CSS class string for a colored badge based on status string. Available in all views.

```erb
<span class="<%= status_badge_class(booking.status) %>">
  <%= booking.status.titleize %>
</span>
```

Supported statuses: `pending`, `confirmed`, `checked_in`, `checked_out`, `cancelled`, `completed`, `new`, `read`, `replied`.

---

## Room Pricing Logic

Prices are resolved in `RoomType#price_for(date)`:

1. Look for a `Rate` record where `start_date <= date <= end_date`
2. If multiple rates match, pick the one with the highest `priority`
3. Fall back to `base_price_per_night` if no rate matches

To add seasonal pricing, create a `Rate` record via the admin panel under **Room Types → Rates**.

---

## Seeding / Demo Data

`db/seeds.rb` creates:
- 4 room types (Single, Double, Deluxe, Family)
- 13 rooms across 4 floors
- 6 seasonal rates
- 12 facilities
- 3 gallery albums, 13 images
- 6 guests, 9 bookings, 4 reviews
- 26 menu items, 2 dining reservations
- Site settings (name, phone, email, address)

Re-run with: `bundle exec rails db:seed` (clears all existing data first).

---

## Common Rails Commands

```bash
# Check routes
bundle exec rails routes
bundle exec rails routes | grep admin

# Generate things
bundle exec rails generate model MyModel name:string
bundle exec rails generate controller MyController index show
bundle exec rails generate migration AddFieldToTable field:type

# View logs
tail -f log/development.log

# Clear cache
bundle exec rails tmp:clear

# Run a one-off task
bundle exec rails runner "puts Room.count"
```
