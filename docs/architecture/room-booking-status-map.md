# Room / Booking Status Map

This document is a repository-only investigation. It records what the code currently does, separates observed behavior from inference, and intentionally does not change implementation.

## 1. Executive summary

### Observed in code

- Room status is stored on the rooms table and validated as one of: available, maintenance, occupied.
- Booking status is stored on the bookings table and validated as one of: pending, confirmed, checked_in, checked_out, cancelled.
- Availability is checked by Room#available_between? and depends on:
  - the room status must be available;
  - there must be no blocked date record in the room's availabilities table for the selected date range;
  - there must be no overlapping booking where Booking.room_reserving includes pending, confirmed, checked_in.
- The admin rooms page gets room status from the persisted Room#status column, then displays it directly in the view, while also using room.active_bookings.first to show the current guest label.
- The booking admin page gets booking status from the Booking#status column and displays status-specific actions based on that value.
- Room status and Booking status are coupled in the model lifecycle methods: Booking#confirm!, Booking#check_in!, Booking#check_out!, and Booking#cancel! each update both the booking status and its related rooms' status.

### Possible issue / inference

- The admin rooms page offers a filter and summary card for reserved, but the Room model validation and Room::STATUSES do not include reserved. This suggests the codebase has both a UI concept of reserved and a persisted room status model that does not permit it.
- Availability logic is partly a stored room status check and partly a date-overlap query; this means room availability is not purely derived from booking state.
- The current UI uses room.active_bookings.first to show the current guest, while the actual room availability query excludes status values and instead checks Booking.room_reserving over date overlap. This can produce a mismatch between a room's displayed status and what the date-based availability logic says.

### What cannot be established from the repository

- Whether the business intended to have a separate room reserved state, a derived reserved state, or no reserved state at all.
- Whether the room.status column is meant to represent physical room condition, operational availability, or current occupancy.
- Whether the room.status column is authoritative or only a convenience flag.

---

## 2. Status vocabulary

This table includes every status value actually found in the codebase for Room and Booking, based on repository search and model declarations.

| Entity | Exact stored value | Where defined | Where written | Where read | Meaning inferred from surrounding code | Persisted or calculated |
|---|---|---|---|---|---|---|
| Room | available | app/models/room.rb: Room::STATUSES | Room.create!, admin room create/update flows, seed data, Booking lifecycle methods set to available | app/models/room.rb, app/controllers/admin/rooms_controller.rb, app/views/admin/rooms/index.html.erb, app/controllers/admin/reports_controller.rb | Default/normal state; room must be available for availability check; used in Room#available_between? guard | Persisted |
| Room | maintenance | app/models/room.rb: Room::STATUSES | Not set in app logic found; possible manual admin update via room form if room_params allows status | app/views/admin/rooms/index.html.erb filter and summary cards | Explicit UI concept for out-of-service rooms | Persisted |
| Room | occupied | app/models/room.rb: Room::STATUSES | Booking#confirm! and Booking#check_in! set room.update!(status: "occupied") | app/models/room.rb availability checks, admin room page display, reports, dashboard occupancy calculations | Used as room-level occupancy / in-house state | Persisted |
| Room | reserved | Not in Room::STATUSES; appears in admin UI only | No direct assignment found in repository code; not in Room::STATUSES | app/views/admin/rooms/index.html.erb filter and summary cards | UI-only concept, but not backed by model validation | Not defined as persisted status in model |
| Booking | pending | app/models/booking.rb: STATUSES and scope :pending | Public booking creation sets status: "pending"; admin manual creation sets status: "confirmed" in create flow; no explicit pending set in admin create flow | app/models/booking.rb scopes, views/admin/bookings/index.html.erb, app/views/admin/bookings/show.html.erb, app/controllers/admin/dashboard_controller.rb | Initial reservation state before confirmation | Persisted |
| Booking | confirmed | app/models/booking.rb: STATUSES and scope :confirmed | Booking#confirm! update!(status: "confirmed", confirmed_at: Time.current) | app/models/room.rb active_bookings scope, app/models/booking.rb active and room_reserving scopes, app/views/admin/bookings/index.html.erb, app/views/admin/bookings/show.html.erb, admin reports/revenue | Confirmed reservation; considered active in many queries | Persisted |
| Booking | checked_in | app/models/booking.rb: STATUSES and scope :checked_in | Booking#check_in! update!(status: "checked_in") | app/models/booking.rb active scope, Booking.today_departures, app/views/admin/bookings/show.html.erb, admin dashboard | Guest checked in; still active and room-occupying | Persisted |
| Booking | checked_out | app/models/booking.rb: STATUSES and scope :checked_out | Booking#check_out! update!(status: "checked_out") | app/models/booking.rb today_departures not used; admin views, reports, revenue totals include this state | Completed stay; room status returns to available | Persisted |
| Booking | cancelled | app/models/booking.rb: STATUSES and scope :cancelled | Booking#cancel! update!(status: "cancelled", cancellation_reason: reason, cancelled_at: Time.current) | app/views/admin/bookings/index.html.erb, app/views/admin/bookings/show.html.erb | Cancelled booking; room status set to available | Persisted |
| Booking | unpaid / partial / paid / refunded | app/models/booking.rb: PAYMENT_STATUSES | Booking creation, payment collection flows, seed data | app/views/admin/bookings/index.html.erb and booking show pages | Payment state, not room state | Persisted |

### Observed status values outside the core Room/Booking models

- Dining reservations and conference reservations use their own status values, but they are not part of room or booking status logic.
- Contact inquiries have a separate status field defaulting to new; not relevant to room availability.

---

## 3. Room model investigation

Source: app/models/room.rb

### Associations

- belongs_to :room_type
- has_many :booking_rooms, dependent: :restrict_with_error
- has_many :bookings, through: :booking_rooms
- has_many :availabilities, dependent: :destroy
- has_many :active_bookings, -> { where(status: %w[confirmed checked_in]).order(:check_in_date) }, through: :booking_rooms, source: :booking

### Enums

- No Rails enum is defined.
- Room::STATUSES = %w[available maintenance occupied].freeze
- validates :status, inclusion: { in: STATUSES }

### Validations

- room_number presence and uniqueness
- status inclusion in Room::STATUSES

### Scopes

- scope :available, -> { where(status: "available") }
- scope :ordered, -> { order(:floor, :room_number) }

### Callbacks

- None found in app/models/room.rb.

### Instance methods

| File | Method name | Explanation | Important conditions |
|---|---|---|---|
| app/models/room.rb | available_on?(date) | Returns true only if room status is available and no blocked date exists for that date. | status == "available" and !availabilities.where(blocked_date: date).exists? |
| app/models/room.rb | available_between?(check_in, check_out) | Main availability gate. Returns false if dates blank/invalid, check_out <= check_in, room status not available, blocked_date exists in the range, or a booking overlaps in the range. | Returns false when status != "available"; checks Date overlap with bookings.room_reserving and blocked dates |

### Class methods

- None found in the Room model.

### Status-related methods

| File | Method name | Explanation | Important conditions |
|---|---|---|---|
| app/models/room.rb | available_on?(date) | Status + blocked-date check for a single date. | room.status must be available |
| app/models/room.rb | available_between?(check_in, check_out) | Status + blocked-date + date-overlap check across range. | room.status == "available" required |

### Availability-related methods

- available_on?
- available_between?

### Booking-related methods

- active_bookings association
- bookings through booking_rooms

### Observed behavior

The model does not derive a room's availability from the current date alone; it uses room.status plus bookings overlap and blocked dates. The room.status field is required to be available for the room to pass the main availability check.

---

## 4. Booking model investigation

Source: app/models/booking.rb

### Status definition

- STATUSES = %w[pending confirmed checked_in checked_out cancelled].freeze
- validates :status, inclusion: { in: STATUSES }

### Payment status definition

- PAYMENT_STATUSES = %w[unpaid partial paid refunded].freeze
- validates :payment_status, inclusion: { in: PAYMENT_STATUSES }

### Associations

- belongs_to :guest
- has_many :booking_rooms, dependent: :destroy
- has_many :rooms, through: :booking_rooms
- has_many :room_types, through: :booking_rooms
- has_many :reviews, dependent: :nullify

### Scopes

- pending -> where(status: "pending")
- confirmed -> where(status: "confirmed")
- checked_in -> where(status: "checked_in")
- checked_out -> where(status: "checked_out")
- cancelled -> where(status: "cancelled")
- active -> where(status: %w[confirmed checked_in])
- room_reserving -> where(status: %w[pending confirmed checked_in])
- today_arrivals -> confirmed.where(check_in_date: Date.today)
- today_departures -> checked_in.where(check_out_date: Date.today)

### Callbacks

- after_create_commit :enqueue_admin_booking_notification_job
- after_update_commit :enqueue_admin_booking_update_notification_job, if: :should_enqueue_admin_booking_update_notification?

### Validations

- check_in_date and check_out_date presence
- status inclusion
- payment_status inclusion
- num_adults numericality greater than 0
- custom check_out_after_check_in validation

### Lifecycle methods

| File | Method | What it changes in database | Room state impact |
|---|---|---|---|
| app/models/booking.rb | confirm! | update!(status: "confirmed", confirmed_at: Time.current) on booking; rooms.each { |room| room.update!(status: "occupied") } | room statuses set to occupied |
| app/models/booking.rb | check_in! | update!(status: "checked_in") on booking; rooms.each { |r| r.update!(status: "occupied") } | room statuses set to occupied |
| app/models/booking.rb | check_out! | update!(status: "checked_out") on booking; rooms.each { |r| r.update!(status: "available") } | room statuses set to available |
| app/models/booking.rb | cancel!(reason: nil) | update!(status: "cancelled", cancellation_reason: reason, cancelled_at: Time.current) on booking; rooms.each { |r| r.update!(status: "available") } | room statuses set to available |

### Transition-state methods and other behavior

- nights returns the number of nights between check_in_date and check_out_date.
- balance_due calculates total_amount - paid_amount.
- display_guest_name returns guest_name or guest full name or "—".

### Methods that update Room

- Booking#confirm!
- Booking#check_in!
- Booking#check_out!
- Booking#cancel!

### Methods that determine active/current/upcoming behavior

- Booking.active -> confirmed or checked_in
- Booking.room_reserving -> pending or confirmed or checked_in
- Booking.today_arrivals -> confirmed on today
- Booking.today_departures -> checked_in with checkout today

### Observed behavior

These lifecycle methods are the actual coupling between Booking status and Room status. There is no separate state machine object or callback chain outside these methods.

---

## 5. BookingRoom investigation

Source: app/models/booking_room.rb

### Associations

- belongs_to :booking
- belongs_to :room
- belongs_to :room_type

### Validations

- rate_per_night numericality >= 0
- total_amount numericality >= 0

### Callbacks

- None found in app/models/booking_room.rb.

### Relevant scopes/methods

- None found.

### Relationship map

Observed actual relationship from the join table:

```text
Room
  has_many :booking_rooms
  has_many :bookings, through: :booking_rooms

Booking
  has_many :booking_rooms
  has_many :rooms, through: :booking_rooms

BookingRoom
  belongs_to :booking
  belongs_to :room
  belongs_to :room_type
```

### Actual relationship facts

- A single booking can contain multiple booking_room records; the joins are a many-to-many association via BookingRoom.
- A single room can be associated with multiple booking_room records over time, because there is no uniqueness constraint on room_id + booking_id in the schema.
- RoomType is also stored on each BookingRoom row, not just on Room.

### Small ASCII diagram

```text
Booking 1 ──< BookingRoom >── Room 1
    │
    ├── BookingRoom row for room A
    ├── BookingRoom row for room B
    └── BookingRoom row for room C
```

This indicates the relationship is a join-table model and one booking can span multiple rooms. The room availability query uses the underlying room bookings relation, not a single one-to-one room assignment.

---

## 6. Full status write map

This section documents every place in the repository where a status value is assigned or changed, based on repository search and code inspection.

| Entity | File | Method/context | Status change | Trigger | Notes |
|---|---|---|---|---|---|
| Booking | app/controllers/bookings_controller.rb | public create | status: "pending" | guest booking submission | Booking.created with status pending |
| Booking | app/controllers/admin/bookings_controller.rb | create manual booking | status: "confirmed" | admin manual booking create | Uses Booking.new with status: "confirmed" |
| Booking | app/models/booking.rb | confirm! | update!(status: "confirmed") | admin confirm action | Also sets confirmed_at and room.status = "occupied" |
| Booking | app/models/booking.rb | check_in! | update!(status: "checked_in") | admin check_in action | Also sets room.status = "occupied" |
| Booking | app/models/booking.rb | check_out! | update!(status: "checked_out") | admin check_out action | Also sets room.status = "available" |
| Booking | app/models/booking.rb | cancel! | update!(status: "cancelled") | admin cancel action | Also sets cancelled_at, cancellation_reason, and room.status = "available" |
| Booking | app/models/booking.rb | after_update_commit notification hook | status change triggers admin notification | any booking update where should_enqueue_admin_booking_update_notification? returns true | indirect status write by change detection |
| Room | app/models/booking.rb | confirm! / check_in! / check_out! / cancel! | room.update!(status: "occupied" or "available") | booking lifecycle transition | This is the explicit coupling between room status and booking status |
| Room | app/controllers/admin/rooms_controller.rb | update | @room.update(room_params) | admin edits room | a general update of room fields including status |
| Room | db/seeds.rb | seed data | room status values set to available or occupied | seed script | data setup, not runtime logic |
| Room | test/models/booking_test.rb | booking lifecycle tests | room.status set during confirm! | test setup | verifies behavior in test code |
| Booking | db/migrate/20260823000000_add_guest_name_to_bookings.rb | backfill migration | guest_name update_columns | migration | not status-related but shows direct update_columns appears in repo |

### Update methods found

- update!(status: ...) used in app/models/booking.rb
- update(status: ...) used elsewhere for non-room statuses (for example dining and conference reservations, not booking model status transitions)
- Direct update_column/update_columns/write_attribute were not found in the room/booking state flow. The only direct update_columns found in the repository is the guest_name migration.
- There are no update_attribute or write_attribute calls discovered for room or booking status in this app code.

---

## 7. Full status read map

This section identifies where room and booking status are read or used to drive decisions.

| File | Context | Entity | Status/read logic | Purpose |
|---|---|---|---|---|
| app/models/room.rb | availability guard | Room | status == "available" | blocks room from being considered available |
| app/models/room.rb | bookings overlap | Room + Booking | !bookings.room_reserving.where("check_in_date < ? AND check_out_date > ?", check_out, check_in).exists? | excludes rooms with overlapping active or pending reservations |
| app/models/room.rb | active bookings association | Room | has_many :active_bookings, -> { where(status: %w[confirmed checked_in]).order(:check_in_date) } | current active stay association |
| app/controllers/admin/rooms_controller.rb | admin room listing | Room | @rooms = @rooms.where(status: params[:status]) if params[:status].present? | status filtering for admin room list |
| app/controllers/admin/rooms_controller.rb | summary counts | Room | @room_status_counts = Room.group(:status).count | dashboard summary |
| app/views/admin/rooms/index.html.erb | room status filters | Room | params[:status].to_s == value | selected filter highlight |
| app/views/admin/rooms/index.html.erb | count cards | Room | @room_status_counts.fetch(status, 0) | display summary counts |
| app/views/admin/rooms/index.html.erb | row badge | Room | status_colors[room.status] || ... and room.status.titleize | display room status on each row |
| app/views/admin/rooms/index.html.erb | current guest | Room | active_booking = room.active_bookings.first | show current guest for active booking |
| app/models/booking.rb | active scope | Booking | status in %w[confirmed checked_in] | identifies active bookings |
| app/models/booking.rb | room reserving scope | Booking | status in %w[pending confirmed checked_in] | identifies reservations that overlap room availability |
| app/controllers/admin/bookings_controller.rb | filter | Booking | @bookings.where(status: params[:status]) if params[:status].present? | booking list status filter |
| app/views/admin/bookings/index.html.erb | status badge | Booking | badge_colors[booking.status] | row display |
| app/views/admin/bookings/show.html.erb | action buttons | Booking | @booking.status == "pending" / "confirmed" / "checked_in" / != "cancelled" | determine which actions are valid |
| app/controllers/admin/dashboard_controller.rb | occupancy by room type | Room | room_counts grouped by room_type_id and status; occupied where status == "occupied" | occupancy dashboard |
| app/controllers/admin/reports_controller.rb | occupancy report | Room | Room.where(status: "occupied").count | reports page |
| app/controllers/admin/reports_controller.rb | revenue report | Booking | Booking.where(status: %w[confirmed checked_in checked_out]) | revenue totals |
| app/jobs/monthly_report_job.rb | monthly revenue | Booking | Booking.where(status: %w[confirmed checked_in checked_out]) | monthly reporting |
| app/views/admin/dashboard/index.html.erb | dashboard listing | Booking | booking.status.titleize with badge_colors[booking.status] | display booking status |
| app/views/bookings/show.html.erb | guest booking page | Booking | @booking.status.titleize | status display |
| app/models/admin_notification.rb | notification body | Booking | booking.status.titleize | notification copy |
| app/models/booking.rb | update notification gating | Booking | saved_change_to_status? || ... | triggers admin update notifications on status changes |

### Important read-side observations

- The admin room listing counts and filters are based on the persisted Room#status column, not on active bookings.
- The room row's current guest is derived from Booking rows via the active_bookings association, not from Room#status itself.
- The admin booking listing and action buttons are directly driven by Booking#status, which is a separate lifecycle than the Room#status lifecycle.

---

## 8. Availability logic

### Core implementation

The actual availability logic is in:

- app/models/room.rb: Room#available_between?
- app/models/room_type.rb: RoomType#available_rooms_count
- app/controllers/bookings_controller.rb: public booking creation availability check
- app/controllers/admin/bookings_controller.rb: admin manual booking creation availability check
- app/controllers/rooms_controller.rb: public room list filtering
- app/controllers/bookings_controller.rb: check_availability

### Actual logic in Room#available_between?

Observed code:

```ruby
return false if check_in.blank? || check_out.blank?
return false if check_out <= check_in
return false unless status == "available"

blocked = availabilities
  .where(blocked_date: check_in...check_out)
  .exists?

return false if blocked

!bookings
  .room_reserving
  .where(
    "check_in_date < ? AND check_out_date > ?",
    check_out,
    check_in
  )
  .exists?
```

### Meaning of the logic

A room is considered unavailable if any of the following is true:

- the date range is invalid or blank
- check_out <= check_in
- room.status != "available"
- a blocked date exists across the date range
- an overlapping booking exists with status in pending, confirmed, or checked_in

This means the query tests overlap with the half-open range condition:

- booking.check_in_date < check_out
- booking.check_out_date > check_in

### What is checked

| Factor | Source | Used in availability? |
|---|---|---|
| Room.status | rooms.status | Yes, hard gate |
| Booking.status | bookings.status | Yes, via Booking.room_reserving scope |
| dates | check_in/check_out | Yes |
| BookingRoom | join table | Indirectly, via room.bookings relation |
| blocked availability records | availabilities table | Yes |
| room_type | not directly | no |

### Observed date-overlap rules

For a selected room and candidate range:

- If a booking overlaps by date, the room is not available.
- Overlap test uses the condition check_in_date < candidate_check_out AND check_out_date > candidate_check_in.
- This is a standard inclusive/exclusive date overlap check.

### Possible issue / inference

- The room can only be available if its stored status is available, even if there are no overlapping bookings and no blocked dates.
- A room can be occupied in the database but still have no overlapping booking data, if the room status was manually updated or stale data exists.
- There is no direct logic that infers availability from `active_bookings` alone; it is date overlap plus stored room status.

---

## 9. Admin Rooms page

Source:

- app/controllers/admin/rooms_controller.rb
- app/views/admin/rooms/index.html.erb
- app/views/admin/rooms/show.html.erb

### Controller flow

`Admin::RoomsController#index`:

```ruby
@rooms = Room
  .preload(:room_type, active_bookings: :guest)
  .order(:room_number)
@rooms = @rooms.where(status: params[:status]) if params[:status].present?

@room_status_counts = Room.group(:status).count
```

### Instance variables

- @rooms: all rooms with room_type and active_bookings preloaded; optional status filter by params[:status]
- @room_status_counts: Room.group(:status).count

### Status filtering

The view includes filter links:

- All
- Available
- Occupied
- Maintenance
- Reserved

The view uses:

```erb
<%= link_to label, admin_rooms_path(status: value.presence) %>
```

The selected state is computed from params[:status].

### Status summary cards

The summary cards are hardcoded in the view:

```erb
statuses = { "available" => [...], "occupied" => [...], "maintenance" => [...], "reserved" => [...] }
```

Then counts are fetched with:

```erb
@room_status_counts.fetch(status, 0)
```

### Individual room status display

Each row does:

```erb
active_booking = room.active_bookings.first
status_colors = {
  "available" => "bg-green-100 text-green-700",
  "occupied" => "bg-red-100 text-red-700",
  "maintenance" => "bg-yellow-100 text-yellow-700",
  "reserved" => "bg-blue-100 text-blue-700"
}
```

and then:

```erb
<span class="badge <%= status_colors[room.status] || 'bg-gray-100 text-gray-500' %>"><%= room.status.titleize %></span>
```

This means the row status is displayed directly from room.status value.

### Current guest display

In the same row:

```erb
active_booking = room.active_bookings.first
...
<% if active_booking %>
  <%= active_booking.display_guest_name %><br>
  <span class="text-gray-400">until <%= active_booking.check_out_date.strftime("%d %b") %></span>
<% else %>
  <span class="text-gray-300">—</span>
<% end %>
```

This uses the active_bookings association rather than Room#status to decide who is currently linked to that room.

### Summary

- Displayed room status comes directly from Room.status in the view.
- Current guest comes from Room.active_bookings.first, a separate association that is filtered by Booking.status values [%w[confirmed checked_in]].
- There is a separate UI concept reserved not present in the model status list.

---

## 10. Admin Bookings lifecycle

This section traces the major booking lifecycle flows from controller to database state and room state, based on code and model actions.

### 1) Manual admin booking create

Flow:

- app/controllers/admin/bookings_controller.rb: create
- validation for dates, room_type, room number, guest details
- uses @room_type.rooms.ordered.select { |room| room.available_between?(@check_in, @check_out) }
- on success creates Booking.new with:
  - guest: @guest
  - check_in_date, check_out_date
  - special_requests, num_adults, num_children
  - status: "confirmed"
  - payment_status: input[:payment_status].presence || "unpaid"
  - total_amount: @total
- transaction saves guest, booking, and BookingRoom record

Database changes:

- INSERT into bookings with status = confirmed
- INSERT into booking_rooms linking room and booking
- room remains as is unless Booking#confirm! is called later; in admin create flow, the booking is created with status confirmed and room status is not changed here because the controller does not call Booking#confirm!

Observed inconsistency:

- The admin create action creates a booking with booking.status = confirmed, but it does not call Booking#confirm!.
- The Booking#confirm! method itself sets room.status = occupied; the controller direct create path does not.

### 2) Public guest booking create

Flow:

- app/controllers/bookings_controller.rb: create
- validates guest and date range
- finds available room via room.available_between?
- creates Booking with status: "pending"
- saves booking and booking_rooms

Database changes:

- INSERT into bookings with status = pending
- INSERT into booking_rooms linking room and booking

Room state:

- No Room#status update in this path.
- The chosen room is chosen only because room.available_between? returned true.

### 3) Confirm booking

Flow:

- app/views/admin/bookings/show.html.erb button for pending bookings
- app/controllers/admin/bookings_controller.rb: confirm
- calls @booking.confirm!

Model effect:

```ruby
update!(status: "confirmed", confirmed_at: Time.current)
rooms.each { |room| room.update!(status: "occupied") }
```

Database effects:

- UPDATE bookings.status = confirmed
- UPDATE bookings.confirmed_at = Time.current
- UPDATE rooms.status = occupied for each related room

Jobs:

- enqueue_confirmation_job
- schedule_reminder_job

Potential side effect:

- BookingConfirmationJob sends confirmation email

### 4) Check in guest

Flow:

- app/views/admin/bookings/show.html.erb button for confirmed bookings
- app/controllers/admin/bookings_controller.rb: check_in
- calls @booking.check_in!

Model effect:

```ruby
update!(status: "checked_in")
rooms.each { |r| r.update!(status: "occupied") }
```

Database effects:

- UPDATE bookings.status = checked_in
- UPDATE rooms.status = occupied for related rooms

### 5) Check out guest

Flow:

- app/views/admin/bookings/show.html.erb button for checked_in bookings
- app/controllers/admin/bookings_controller.rb: check_out
- calls @booking.check_out!

Model effect:

```ruby
update!(status: "checked_out")
rooms.each { |r| r.update!(status: "available") }
```

Database effects:

- UPDATE bookings.status = checked_out
- UPDATE rooms.status = available

### 6) Cancel booking

Flow:

- app/views/admin/bookings/show.html.erb cancel form/button
- app/controllers/admin/bookings_controller.rb: cancel
- calls @booking.cancel!(reason: params[:reason])

Model effect:

```ruby
update!(status: "cancelled", cancellation_reason: reason, cancelled_at: Time.current)
rooms.each { |r| r.update!(status: "available") }
```

Database effects:

- UPDATE bookings.status = cancelled
- UPDATE bookings.cancellation_reason
- UPDATE bookings.cancelled_at
- UPDATE rooms.status = available for each related room

Jobs:

- BookingCancellationJob sends cancellation email

### 7) Update/edit booking

Flow:

- app/controllers/admin/bookings_controller.rb: update
- updates booking attributes
- if booking_room exists and room number or room type selected, updates booking_room.room or room_type

Database effects:

- UPDATE bookings row with permitted fields
- UPDATE booking_rooms row when room or room_type is changed

Room state:

- No explicit room.status update occurs in this action.
- The controller does not call any booking lifecycle transition method here.

---

## 11. Services, concerns, helpers and indirect logic

This repository does not show a dedicated room status service or state machine. The relevant logic is spread across model methods and controllers, but the following files are relevant to room/booking state or availability.

### Directly relevant code

- app/models/room.rb
- app/models/booking.rb
- app/models/booking_room.rb
- app/models/availability.rb
- app/models/room_type.rb
- app/controllers/bookings_controller.rb
- app/controllers/admin/bookings_controller.rb
- app/controllers/admin/rooms_controller.rb
- app/controllers/admin/availabilities_controller.rb
- app/controllers/rooms_controller.rb
- app/views/admin/rooms/index.html.erb
- app/views/admin/bookings/show.html.erb

### Indirectly relevant code

- app/controllers/admin/dashboard_controller.rb
- app/controllers/admin/reports_controller.rb
- app/jobs/admin_booking_notification_job.rb
- app/jobs/booking_confirmation_job.rb
- app/jobs/booking_cancellation_job.rb
- app/jobs/booking_reminder_job.rb
- app/jobs/monthly_report_job.rb
- app/models/admin_notification.rb
- app/helpers/application_helper.rb

### Observed behavior

- There is no standalone concern or service object that owns room/booking transitions.
- Room and Booking states are largely managed in the models themselves.
- The admin notification job and booking reminder job do not alter booking or room state, but they are triggered from booking lifecycle methods or callbacks.

---

## 12. Notifications and background jobs

The repository does include notification and email jobs that can be triggered by booking lifecycle events.

### Trigger points

- Booking#after_create_commit :enqueue_admin_booking_notification_job
- Booking#after_update_commit :enqueue_admin_booking_update_notification_job, if: :should_enqueue_admin_booking_update_notification?
- Booking#confirm! -> enqueue_confirmation_job and schedule_reminder_job
- Booking#cancel! -> enqueue_cancellation_job

### Actual job files

- app/jobs/admin_booking_notification_job.rb: creates or updates AdminNotification records and calls AdminNotification.broadcast_widget!
- app/jobs/booking_confirmation_job.rb: sends a confirmation email using BrevoMailer
- app/jobs/booking_cancellation_job.rb: sends cancellation email
- app/jobs/booking_reminder_job.rb: sends reminder email

### Does any async process alter room state?

From the repository inspection, no background job updates room.status or booking.status directly. The jobs only send mail or notifications.

### Turbo / ActionCable behavior

- app/models/admin_notification.rb: calls Turbo::StreamsChannel.broadcast_update_to for admin_notifications channel
- This updates notification widgets, not room or booking records.

---

## 13. Routes

Source: config/routes.rb

### Public room/booking routes

- resources :rooms, param: :slug, only: [ :index, :show ]
- resources :bookings, only: [ :new, :create, :show ] do
  - collection do
    - get :check_availability
    - post :hold
  end
end

### Admin room routes

- namespace :admin do
  - resources :rooms do
    - resources :availabilities, only: [ :index, :create, :destroy ]
    end
  - resources :room_types do
    - resources :rates
    end
  - resources :bookings do
    - member do
      - patch :confirm
      - patch :check_in
      - patch :check_out
      - patch :cancel
    end
  end
end

### Observed actions

- confirm action on booking is PATCH /admin/bookings/:id/confirm
- check_in is PATCH /admin/bookings/:id/check_in
- check_out is PATCH /admin/bookings/:id/check_out
- cancel is PATCH /admin/bookings/:id/cancel

### Availability-related routes

- GET /bookings/check_availability
- GET /rooms
- GET /rooms/:slug

---

## 14. Database/schema investigation

Source: db/schema.rb and db/migrate/20260515105705_create_availabilities.rb

### rooms table

Schema fields:

- room_number, floor, notes, room_type_id
- status default: "available", null: false
- indexes: room_number unique, room_type_id, status

Constraints:

- database does not enforce an enum list on status at the DB layer
- model validation enforces allowed values at the Rails level

### bookings table

Schema fields:

- check_in_date null: false
- check_out_date null: false
- guest_id null: false
- status default: "pending"
- payment_status default: "unpaid"
- confirmed_at, cancelled_at, cancellation_reason
- indexes: check_in_date, check_out_date, guest_id, status, status+check_in_date

Constraints:

- no database enum on status or payment_status
- no explicit database constraint preventing invalid booking status strings

### booking_rooms table

Schema fields:

- booking_id, room_id, room_type_id
- rate_per_night, total_amount
- indexes on booking_id, room_id, room_type_id

Constraints:

- foreign keys exist for booking_id, room_id, room_type_id
- there is no uniqueness constraint on (booking_id, room_id)

### availabilities table

Schema fields:

- room_id foreign key
- blocked_date, reason
- unique composite index on [room_id, blocked_date]

This means the code protects against duplicate blocked_date entries for a given room.

### Observed database-level protections

- There is no database-level enum restriction for status fields.
- Validation is in ActiveRecord models, not in SQL constraints.
- There is no database constraint ensuring room.status can only be one of the allowed values.

---

## 15. Tests

Source search from test directory.

| Test | File | What behavior it protects | Missing coverage noticed |
|---|---|---|---|
| test_confirm_marks_booking_room_occupied | test/models/booking_test.rb | confirms Booking#confirm! updates booking status and room status | does not test check_in/check_out/cancel status transitions on room status |
| test_available_rooms_count_ignores_occupied_rooms | test/models/booking_test.rb | ensures room_type.available_rooms_count counts only open rooms | no direct test for blocked date availability or pending overlap edge cases |
| test_confirm_falls_back_to_immediate_job_execution_when_queue_enqueue_fails | test/models/booking_test.rb | tests fallback job execution on confirmation | no direct test for cancellation reminder fallback |
| test_enqueue_admin_booking_notification_job_delegates_to_job | test/models/booking_test.rb | suppresses notification enqueues in thread context | no test for notification body/status wording |
| test_booking_update_creates_admin_notification | test/models/booking_test.rb | update notifications fire on booking changes | no direct test for room status update after booking lifecycle |
| test_admin_update_does_not_create_notification | test/models/booking_test.rb | suppresses admin update notifications | no coverage for when room status is changed as part of booking lifecycle |
| admin can create a manual walk-in booking | test/controllers/bookings_controller_test.rb | admin booking creation creates pending booking with correct guest | does not assert room.status after admin create |
| rerenders the admin booking form with submitted values when guest data is invalid | test/controllers/bookings_controller_test.rb | validation and form state restoration | no room status coverage |
| rejects invalid guest fields on booking create | test/controllers/bookings_controller_test.rb | public booking creation validation | no overlapping-date block test |
| allows repeat email with a different valid name without updating the existing guest | test/controllers/bookings_controller_test.rb | guest deduplication and guest_name assignment | no room availability coverage |

### Missing coverage noticed

- no tests for Booking#check_in!, Booking#check_out!, and Booking#cancel! room state updates
- no tests for room.status reserved behavior or UI filter mismatch
- no integration test covering room availability when joined Booking.status is pending, confirmed, checked_in, cancelled, or checked_out
- no test for `available_between?` on blocked_date records with date range overlap

---

## 16. State transition map

### Booking state transitions actually implemented

Observed from model lifecycle methods and admin actions:

```text
pending
  -> confirmed via Booking#confirm!
  -> cancelled via Booking#cancel!

confirmed
  -> checked_in via Booking#check_in!
  -> cancelled via Booking#cancel!
  -> checked_out via Booking#check_out! (not explicitly blocked in code, but admin show page only shows check-in button at confirmed state)

checked_in
  -> checked_out via Booking#check_out!
  -> cancelled via Booking#cancel! (admin UI hides cancel when status == "cancelled" only; it does not block cancel during checked_in, so the method is callable)

checked_out
  -> no further state transition in current app logic found

cancelled
  -> no further transition in current app logic found
```

### Room state transitions actually implemented

Observed from Booking lifecycle methods:

```text
available
  -> occupied via Booking#confirm! or Booking#check_in!
  -> available via Booking#check_out! or Booking#cancel!

occupied
  -> available via Booking#check_out! or Booking#cancel!

maintenance
  -> no code path found that explicitly transitions maintenance to available or occupied in booking lifecycle
```

### Important note

The Room model itself does not define a state machine or callback-based transition system. The room status changes are implemented in Booking lifecycle methods as direct room.update!(status: ...) calls.

---

## 17. Potential inconsistencies to investigate

### Potential inconsistencies to investigate

1. Room.status versus Booking.status
   - Evidence: app/models/room.rb status values are available/maintenance/occupied; app/models/booking.rb status values are pending/confirmed/checked_in/checked_out/cancelled.
   - File: app/models/room.rb; app/models/booking.rb
   - Existing behavior: booking lifecycle updates both booking.status and room.status in separate model methods.
   - Why it may cause inconsistent UI/state: the same operational concept (stay occupancy/reservation status) is split across two different tables and two different vocabularies.
   - Confidence: High

2. Stored versus calculated room status
   - Evidence: Room#available_between? requires room.status == "available" and also checks overlap/blocked dates.
   - File: app/models/room.rb
   - Existing behavior: room availability is both a persisted state and a computed check.
   - Why it may cause inconsistent UI/state: a room can be marked available in the DB but still not be date-available due to overlap; or a room can appear occupied in the DB but be considered available by a future derived rule set.
   - Confidence: High

3. active_bookings.first
   - Evidence: app/views/admin/rooms/index.html.erb sets active_booking = room.active_bookings.first, and Room#active_bookings is filtered to confirmed and checked_in.
   - File: app/views/admin/rooms/index.html.erb; app/models/room.rb
   - Existing behavior: the row displays only the first active booking as the current guest.
   - Why it may cause inconsistent UI/state: a room can have multiple active bookings and only the first one appears, while availability checks are based on overlap across all bookings.
   - Confidence: High

4. Future confirmed bookings
   - Evidence: Booking.room_reserving includes pending, confirmed, checked_in; Room#available_between? excludes bookings with overlapping date ranges even when status is confirmed.
   - File: app/models/room.rb; app/models/booking.rb
   - Existing behavior: future confirmed bookings count as reservation overlap and block availability.
   - Why it may cause inconsistent UI/state: a room that is currently available may still be shown as occupied in the room list if room.status was manually set or stale.
   - Confidence: Medium

5. pending bookings
   - Evidence: Room#available_between? excludes bookings with status in %w[pending confirmed checked_in].
   - File: app/models/room.rb; app/models/booking.rb
   - Existing behavior: pending bookings are considered reserving for room availability purposes.
   - Why it may cause inconsistent UI/state: pending reservations are treated as blocking availability even before confirmation, which may conflict with a room status label that says available.
   - Confidence: High

6. checked-out bookings
   - Evidence: Booking.check_out! sets room.status = "available" and Booking.status = "checked_out".
   - File: app/models/booking.rb
   - Existing behavior: checked_out remains in the Booking status vocabulary and revenue reports include checked_out.
   - Why it may cause inconsistent UI/state: checked_out is an historical booking state, but a room status can also be available, so the room is not considered occupied after checkout.
   - Confidence: Medium

7. cancelled bookings
   - Evidence: Booking#cancel! sets booking.status = "cancelled" and room.status = "available".
   - File: app/models/booking.rb
   - Existing behavior: cancelled bookings are excluded from active status filters and block availability through room_reserving? no, they are not included in room_reserving.
   - Why it may cause inconsistent UI/state: a cancelled booking still appears in the booking list as a distinct status but usually no longer blocks room availability.
   - Confidence: Medium

8. maintenance rooms
   - Evidence: Room::STATUSES includes maintenance; Room#available_between? immediately returns false unless status == "available".
   - File: app/models/room.rb
   - Existing behavior: maintenance rooms are treated as unavailable even if they have no booking overlap.
   - Why it may cause inconsistent UI/state: if a room is marked maintenance but also has an active booking, the code will still render it in the room list with maintenance status and a guest from active_bookings.
   - Confidence: Medium

9. multiple bookings for one room
   - Evidence: no uniqueness constraint on booking_rooms and room.bookings can include many bookings.
   - File: app/models/booking_room.rb; db/schema.rb
   - Existing behavior: room is connected to bookings via join table and overlap check queries all of them.
   - Why it may cause inconsistent UI/state: multiple overlapping bookings can exist as data, and the room could still be shown as occupied or available depending on which row is chosen in the UI.
   - Confidence: High

10. status filtering versus displayed status
   - Evidence: admin room filters and summary cards include reserved, but model validation excludes it.
   - File: app/controllers/admin/rooms_controller.rb; app/views/admin/rooms/index.html.erb; app/models/room.rb
   - Existing behavior: the filter UI expects reserved even though Room::STATUSES does not.
   - Why it may cause inconsistent UI/state: filtered counts may show states that cannot be persisted through the Room validation layer.
   - Confidence: High

11. summary counts versus individual rows
   - Evidence: @room_status_counts = Room.group(:status).count; each row displays room.status directly; no derived aggregate is used for row display.
   - File: app/controllers/admin/rooms_controller.rb; app/views/admin/rooms/index.html.erb
   - Existing behavior: summary card counts are based on the room table; row display is based on direct room.status values.
   - Why it may cause inconsistent UI/state: if a room is manually in a state not allowed by validation, summary counts and rows may not match what the filter options expect.
   - Confidence: Medium

12. callbacks/services that may update status
   - Evidence: booking lifecycle methods directly update room records; there are no explicit room callbacks or service objects found.
   - File: app/models/booking.rb; app/models/room.rb
   - Existing behavior: state change still occurs in model methods rather than a service layer.
   - Why it may cause inconsistent UI/state: state logic is split between controller actions and model methods, with UI actions controlling when to invoke them.
   - Confidence: Medium

13. date-based availability versus current occupancy
   - Evidence: room.available_between? checks both room.status and bookings overlap.
   - File: app/models/room.rb
   - Existing behavior: room availability for a date range is computed on a date-based algorithm, while room occupancy status is stored separately.
   - Why it may cause inconsistent UI/state: a room can be labeled occupied or available without those values necessarily matching the date-range availability query for future dates.
   - Confidence: High

### What is not established

- Whether the reserved state is intentionally unsupported UI-only.
- Whether room.status is intended to be a direct operational flag, a legacy artifact, or a derived view-model.
- Whether multiple bookings per room are expected or accidental.

---

## 18. Source-of-truth map

| Concept | Current source of truth | Stored or calculated | Main code location |
|---|---|---|---|
| Room physical condition | Room.status | Stored | app/models/room.rb; db/schema.rb |
| Room occupancy | Room.status and Booking lifecycle updates | Stored, then used as status | app/models/booking.rb; app/models/room.rb |
| Room reservation / active guest | room.active_bookings association and Booking.status | Calculated from join table + booking status | app/models/room.rb; app/views/admin/rooms/index.html.erb |
| Booking lifecycle | Booking.status | Stored | app/models/booking.rb |
| Availability | room.status + availabilities + overlapping room_reserving bookings | Calculated | app/models/room.rb; app/models/availability.rb; app/models/booking.rb |

---

## 19. Files requiring attention

### Directly involved

- app/models/room.rb
- app/models/booking.rb
- app/models/booking_room.rb
- app/models/availability.rb
- app/models/room_type.rb
- app/controllers/bookings_controller.rb
- app/controllers/admin/bookings_controller.rb
- app/controllers/admin/rooms_controller.rb
- app/controllers/admin/availabilities_controller.rb
- app/views/admin/rooms/index.html.erb
- app/views/admin/bookings/show.html.erb
- db/schema.rb

### Indirectly involved

- app/controllers/admin/dashboard_controller.rb
- app/controllers/admin/reports_controller.rb
- app/controllers/rooms_controller.rb
- app/jobs/admin_booking_notification_job.rb
- app/jobs/booking_confirmation_job.rb
- app/jobs/booking_cancellation_job.rb
- app/jobs/booking_reminder_job.rb
- app/jobs/monthly_report_job.rb
- app/models/admin_notification.rb
- app/helpers/application_helper.rb

### Tests

- test/models/booking_test.rb
- test/controllers/bookings_controller_test.rb

### Unknown / needs clarification

- Whether a separate room reserved state is intended but absent
- Whether room.status is meant to be authoritative or only a convenience flag
- Whether multiple active/relevant bookings per room are expected business behavior
- Whether the room and booking status vocabularies are intentionally separate or a legacy mismatch

---

Recommended next investigation

Inspect these files together next to establish the correct domain model before making any implementation changes:

- app/models/room.rb
- app/models/booking.rb
- app/models/booking_room.rb
- app/models/availability.rb
- app/controllers/admin/rooms_controller.rb
- app/views/admin/rooms/index.html.erb
- app/controllers/admin/bookings_controller.rb
- db/schema.rb

This is the smallest set of code paths that directly defines the room status model, booking lifecycle, room-to-booking relationship, and the admin UI that exposes the mismatch.
