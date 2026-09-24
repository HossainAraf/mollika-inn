# Hotwire in Mollika Inn

This app uses Hotwire as its default frontend pattern: Turbo handles page navigation and partial updates, Stimulus provides lightweight client-side behavior, and Action Cable + Turbo Streams provide real-time updates without a separate JavaScript frontend.

## 1. Stack setup

The app is configured as a standard Rails 8 + Importmap app:

- `app/javascript/application.js` imports `@hotwired/turbo-rails`
- `config/importmap.rb` pins Turbo, Stimulus, and Stimulus loading packages
- `app/views/layouts/application.html.erb` and `app/views/layouts/admin.html.erb` include `javascript_importmap_tags`
- `data-turbo-track="reload"` is attached to asset tags so Turbo reloads relevant assets when needed

This means the app keeps a Rails-native architecture without a Node build step or a separate frontend app.

## 2. Turbo Drive

Turbo Drive is enabled by default through the Turbo Rails package. It intercepts normal link and form navigation and updates the page without a full browser reload.

Common patterns in the app include:

- standard Rails navigation stays fast and page transitions feel app-like
- non-GET actions use Turbo-compatible attributes such as `data: { turbo_method: :patch }`
- admin sidebar links use `data-turbo-frame="_top"` to force full-page replacement for navigation that should reset the app frame

This is used for a cleaner experience across the admin area and guest-facing pages without building custom JS routing.

## 3. Turbo Frames

Turbo Frames are intended for partial-page updates inside a specific region of the page.

The booking flow is the clearest example of the intended pattern:

- the booking summary section can be isolated into a frame
- a date form submits to the same page or a targeted endpoint
- Turbo replaces only that frame instead of reloading the full page

The app has not overused frames yet; most interactive sections rely on Rails form submissions plus Turbo’s default navigation behavior.

## 4. Turbo Streams + Action Cable

The strongest real-time Hotwire implementation in this app is the admin notification system.

Key pieces:

- `app/models/admin_notification.rb` defines `broadcast_widget!`
- `Turbo::StreamsChannel.broadcast_update_to` replaces specific DOM targets such as:
  - `admin-notification-count`
  - `admin-notification-list`
- `app/views/layouts/admin.html.erb` includes `<%= turbo_stream_from "admin_notifications" %>` to subscribe the admin page to that stream
- `config/routes.rb` mounts Action Cable at `/cable`

This lets the admin dashboard update without polling. When a new booking notification is created, the server pushes a DOM replacement to the client.

## 5. Stimulus controllers

Stimulus is used for lightweight interactions that need DOM state or client-side logic without building a custom frontend framework.

Examples in the app:

- `app/javascript/controllers/booking_form_controller.js`
- `app/javascript/controllers/mobile_nav_controller.js`

The booking form controller watches date and room selectors and recalculates totals based on room rate and nights. This is a good fit for Stimulus because it is modest, declarative, and stays close to the Rails view layer.

Recent findings & actionable notes:

- The `booking_form_controller` lives at `app/javascript/controllers/booking_form_controller.js` and is registered in `app/javascript/controllers/index.js` as `booking-form`.
- It supports two input naming conventions (`booking[check_in_date]` and `check_in`) and updates the visible `nights` and `totalAmount` targets on `input` and `change` events.
- The controller reads per-night `rate` from either a `select[name="booking[room_type_id]"]` rates map or a hidden input with `data-booking-form-target="rate"` (the view provides this hidden input in `app/views/bookings/new.html.erb`).
- To ensure immediate UI updates, date inputs should use `data-action="input->booking-form#updateTotal change->booking-form#updateTotal"` (the booking `new` view is updated accordingly).

Recommendations / best practices:

- Prefer `data-action` that calls `updateTotal` on `input` for instant feedback; use `change` as a fallback for non-typing interactions (date pickers still fire `input` in modern browsers).
- Keep the `rate` source explicit in the view (hidden input or select `data-rate` attributes). If the rate can vary by date, consider returning per-night rates via an API endpoint or server-rendered partial into the frame.
- Avoid requiring Stimulus `targets` that may not exist on all pages; use `querySelector` fallbacks in the controller when reading optional elements.

Debugging notes observed while updating the controller:

- While iterating on the controller, console errors arose when compiled assets expected a `rate` target but the view didn't provide it. The fix was to (a) read the `rate` element safely via querySelector, and (b) add a hidden `data-booking-form-target="rate"` input in the `bookings/new` view as a compatibility shim.
- The app runs without a Node.js build pipeline (importmap), so after editing Stimulus source files you should restart the Rails server in development to ensure the browser loads the updated compiled assets (or clear asset cache if using precompiled assets).


## 6. Rails + Hotwire conventions used here

The project follows these conventions:

- keep business logic in Rails models/controllers
- use ERB views with minimal JS
- prefer declarative DOM hooks like `data-controller`, `data-target`, and `data-action`
- use Turbo semantics for navigation and live updates
- use Stimulus only for browser behavior that is too interactive for pure server-rendered HTML

## 7. Practical outcome

The overall result is a Rails app that feels modern and responsive without a heavy frontend stack:

- pages update in-place where needed
- live admin updates appear without polling
- JavaScript stays small and maintainable
- the app remains idiomatic to Rails and easy to extend

In short, this project uses Hotwire as the default UI layer: Turbo for navigation and streaming, Stimulus for small interactive widgets, and Action Cable for real-time admin updates.
