# Notification System

This application implements a lightweight real-time admin notification system for guest and reservation events. The system is designed to notify the internal admin dashboard immediately when new bookings, conference reservations, or dining reservations are created, and when key booking details change.

## 1. Overview

The notification system is built around a central `AdminNotification` model that stores notification records in the database and drives the live admin UI. The flow is:

1. A guest action creates or updates a record such as a booking, conference reservation, or dining reservation.
2. A model callback enqueues a background job.
3. The background job creates a notification row with a title and message body.
4. The system broadcasts a fresh notification widget through Turbo Streams and Action Cable.
5. The admin dashboard updates in real time without polling.

The key implementation files are:

- [app/models/admin_notification.rb](../app/models/admin_notification.rb)
- [app/models/booking.rb](../app/models/booking.rb)
- [app/models/conference_reservation.rb](../app/models/conference_reservation.rb)
- [app/models/dining_reservation.rb](../app/models/dining_reservation.rb)
- [app/jobs/admin_booking_notification_job.rb](../app/jobs/admin_booking_notification_job.rb)
- [app/jobs/admin_conference_reservation_notification_job.rb](../app/jobs/admin_conference_reservation_notification_job.rb)
- [app/jobs/admin_dining_reservation_notification_job.rb](../app/jobs/admin_dining_reservation_notification_job.rb)
- [app/controllers/admin/notifications_controller.rb](../app/controllers/admin/notifications_controller.rb)
- [app/views/admin/notifications/_widget.html.erb](../app/views/admin/notifications/_widget.html.erb)
- [app/views/layouts/admin.html.erb](../app/views/layouts/admin.html.erb)
- [db/migrate/20260821000000_create_admin_notifications.rb](../db/migrate/20260821000000_create_admin_notifications.rb)

---

## 2. Data model

The main notification record is stored in the `mollika.admin_notifications` table.

### Schema

The migration creates the following columns:

- `booking_id`: optional foreign key to the booking record
- `notification_type`: the event type, such as `booking_created`, `booking_updated`, `conference_reservation_created`, or `dining_reservation_created`
- `title`: short human-readable label
- `body`: full message text shown in the UI
- `read_at`: timestamp used to track unread state
- `created_at`, `updated_at`: audit timestamps

Important indexes include:

- `read_at + created_at` for unread/recent ordering
- `notification_type` for filtering by event type

The model includes:

- `belongs_to :booking, optional: true`
- `scope :unread` for unread notifications
- `scope :recent` for newest-first ordering
- `mark_as_read!` to set `read_at`
- `read?` to check whether a notification has been viewed
- `broadcast_widget!` to push refreshed widget markup to the admin notification stream

The notification model is the center of the system because it both persists data and renders the live widget for the UI.

---

## 3. Trigger points in the app

### Booking notifications

Bookings trigger notification jobs in [app/models/booking.rb](../app/models/booking.rb):

- `after_create_commit :enqueue_admin_booking_notification_job`
- `after_update_commit :enqueue_admin_booking_update_notification_job, if: :should_enqueue_admin_booking_update_notification?`

This means:

- a newly created booking generates a `booking_created` notification
- a booking update creates a `booking_updated` notification only when relevant fields change, such as status, payment status, dates, guest name, and amounts

The job is enqueued with fallback behavior:

- first it tries `perform_later`
- if enqueueing fails, it falls back to `perform_now` and logs the error

### Conference reservation notifications

Conference reservations trigger a notification job in [app/models/conference_reservation.rb](../app/models/conference_reservation.rb):

- `after_create_commit :enqueue_admin_notification_job`

This creates a notification such as:

- `conference_reservation_created`
- title: `New conference reservation`

### Dining reservation notifications

Dining reservations trigger a job in [app/models/dining_reservation.rb](../app/models/dining_reservation.rb):

- `after_create_commit :enqueue_admin_notification_job`

This creates a notification such as:

- `dining_reservation_created`
- title: `New dining reservation`

---

## 4. Background jobs and notification content

### Booking job

The main booking notification logic lives in [app/jobs/admin_booking_notification_job.rb](../app/jobs/admin_booking_notification_job.rb).

It does the following:

- looks up the booking and associated guest/room data
- creates or updates an `AdminNotification` record
- uses `find_or_initialize_by` for new booking creation to avoid duplicate messages
- creates a `booking_updated` notification for status or details changes
- calls `AdminNotification.broadcast_widget!` at the end

Message examples:

- `John Doe booked Deluxe Room from 18 Sep to 20 Sep.`
- `John Doe's Deluxe Room booking was updated. Current status: Confirmed.`

### Conference reservation job

See [app/jobs/admin_conference_reservation_notification_job.rb](../app/jobs/admin_conference_reservation_notification_job.rb).

It creates a notification with this structure:

- `notification_type: "conference_reservation_created"`
- `title: "New conference reservation"`
- body built from guest name, duration, attendees, and event date

### Dining reservation job

See [app/jobs/admin_dining_reservation_notification_job.rb](../app/jobs/admin_dining_reservation_notification_job.rb).

It creates a notification with:

- `notification_type: "dining_reservation_created"`
- `title: "New dining reservation"`
- body built from guest name, table size, date, and time

---

## 5. Real-time broadcast behavior

The application uses Rails Turbo Streams + Action Cable instead of polling.

### Channel subscription

The admin layout includes the live subscription marker in [app/views/layouts/admin.html.erb](../app/views/layouts/admin.html.erb):

```erb
<%= turbo_stream_from "admin_notifications" %>
```

This subscribes the admin page to the `admin_notifications` stream.

### Broadcast target

`AdminNotification.broadcast_widget!` uses `Turbo::StreamsChannel.broadcast_replace_to`:

```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  "admin_notifications",
  target: "admin-notification-widget",
  partial: "admin/notifications/widget",
  locals: {
    notifications: recent.limit(5).includes(:booking),
    unread_count: unread.count
  }
)
```

This means the admin UI element with id `admin-notification-widget` is replaced with a freshly rendered widget whenever a notification is created or marked read.

### Why this matters

This is important because a simple model callback alone is not always enough. The app intentionally broadcasts from the job itself to ensure the update occurs after the notification record is persisted and the job has completed successfully.

---

## 6. Admin notification UI

The widget is rendered by [app/views/admin/notifications/_widget.html.erb](../app/views/admin/notifications/_widget.html.erb).

### Features

- floating alert bell in the admin header
- unread badge with a pulsing style
- dropdown list of recent notifications
- button to mark all as read
- link to the full notifications index page
- close behavior via JavaScript

The widget renders the latest notifications and passes `unread_count` to the UI so the admin can quickly see new activity.

The notification dropdown is inserted into the admin layout via:

```erb
<%= render partial: "admin/notifications/widget", locals: { notifications: @admin_notifications, unread_count: @admin_unread_notifications_count } %>
```

---

## 7. Read state and notification index

The admin controller in [app/controllers/admin/notifications_controller.rb](../app/controllers/admin/notifications_controller.rb) provides the main notification management actions:

- `index`: loads recent notifications
- `mark_all_read`: marks all unread notifications as read and re-broadcasts the widget
- `mark_read`: marks a specific notification as read and redirects back

The base admin controller also loads notification data for every admin page through `set_admin_notifications` in [app/controllers/admin/base_controller.rb](../app/controllers/admin/base_controller.rb):

```ruby
@admin_notifications = AdminNotification.recent.includes(:booking).limit(5)
@admin_unread_notifications_count = AdminNotification.unread.count
```

This ensures the header widget is available across the admin section without extra page-specific setup.

---

## 8. Route-level access

The admin notification routes are defined in [config/routes.rb](../config/routes.rb):

```ruby
resources :notifications, only: [ :index ] do
  member do
    patch :mark_read
  end
  collection do
    patch :mark_all_read
  end
end
```

These routes are namespaced under `admin`, which means notification actions are part of the protected admin area.

---

## 9. Important implementation notes

### No polling

The app does not rely on polling or repeated page refreshes. Notification updates appear immediately through Action Cable and Turbo Stream replacement.

### Notifications are persisted

Every notification is stored in the database, so admin users can review the full history or unread backlog rather than only live UI updates.

### Booking-specific logic is centralized

Booking events are handled in one model and one job, which keeps the behavior consistent for newly created and updated bookings.

### Fallback safety

When background job enqueueing fails, the app logs the error and executes the job immediately to keep the notification flow resilient.

---

## 10. Typical example flow

A standard booking lifecycle looks like this:

1. Guest submits a booking.
2. `Booking` model runs `after_create_commit`.
3. `Booking#enqueue_admin_booking_notification_job` enqueues `AdminBookingNotificationJob`.
4. The job creates a record in `AdminNotification` with type `booking_created`.
5. `AdminNotification.broadcast_widget!` sends the update to the `admin_notifications` stream.
6. The admin notification widget in the dashboard refreshes automatically.
7. The admin opens the notifications list and marks the message as read.
8. `read_at` is set and the widget updates again.

---

## 11. Extension points

This system is easy to extend for new event types:

- add another callback in the relevant model
- create a matching notification job class
- generate a `notification_type` value
- broadcast the widget after creation
- optionally add a new UI label or filter on the notifications page

This pattern is already used for:

- bookings
- conference reservations
- dining reservations

---

## 12. Summary

The notification system in this application is a hybrid of database-backed admin notifications and real-time Turbo Broadcast updates. It is intentionally built around the admin dashboard workflow so staff can see new hotel activity immediately without manual refreshes. The system is robust, auditable, and easy to extend for additional reservation or operational events.
