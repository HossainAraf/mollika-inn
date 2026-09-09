# Mollika Inn — Admin Panel Guide

## Accessing the Admin Panel

- URL: `/admin`
- Login: `/session/new`
- Default credentials:
  - admin:
  email: admin@mollika.com
  password: mollika2026

> Change credentials via the `ADMIN_EMAIL` and `ADMIN_PASSWORD` environment variables in Replit Secrets.

---

## Dashboard (`/admin`)

The dashboard shows at a glance:

- **Today's Arrivals** — confirmed bookings with check-in today
- **Today's Departures** — checked-in guests checking out today
- **Pending Bookings** — awaiting confirmation
- **Unread Inquiries** — contact form messages not yet read
- **Revenue This Week** — bar chart of daily revenue (confirmed/checked-in/checked-out bookings)
- **Occupancy by Room Type** — filled vs total rooms per type
- **Recent Bookings** — last 5 bookings with guest and status

---

## Bookings (`/admin/bookings`)

### Booking Statuses

| Status         | Meaning                                      |
|----------------|----------------------------------------------|
| `pending`      | Submitted by guest, awaiting admin action    |
| `confirmed`    | Admin confirmed; booking rooms reserved      |
| `checked_in`   | Guest has arrived; rooms remain occupied     |
| `checked_out`  | Guest departed; rooms marked available       |
| `cancelled`    | Cancelled; rooms freed                       |

### Booking Actions

From the booking detail page (`/admin/bookings/:id`):

- **Confirm** — moves `pending → confirmed`, records `confirmed_at`, marks booking rooms `occupied`
- **Check In** — moves `confirmed → checked_in`, marks all booking rooms as `occupied`
- **Check Out** — moves `checked_in → checked_out`, marks rooms as `available`
- **Cancel** — cancels from any state, optionally records a reason, frees rooms

### Filtering

The index supports URL parameters:
- `?status=pending` — filter by status
- `?from=2026-06-01` — check-in date from
- `?to=2026-06-30` — check-out date to

### CSV Export

`/admin/reports/bookings_export` — downloads all bookings as a CSV file.

---

## Rooms (`/admin/rooms`)

Manage individual physical rooms. Each room belongs to a **Room Type**.

**Room statuses:**
- `available` — can accept new bookings
- `occupied` — currently has a checked-in guest
- `maintenance` — blocked from bookings

### Blocked Dates (`/admin/rooms/:id/availabilities`)

Manually block specific dates on a room (e.g., maintenance). These dates are excluded from the availability check even if the room status is `available`.

---

## Room Types (`/admin/room_types`)

Room types define the category of room (Single, Double, Deluxe, Family) with:
- Base price per night
- Max occupancy
- Bed type and size
- Amenities (JSON)
- Photos (Active Storage)

### Seasonal Rates

Each room type can have multiple `Rate` records for seasonal pricing. When a guest searches for availability:
1. The system finds rates where `start_date ≤ check_in ≤ end_date`
2. Picks the highest `priority` rate
3. Falls back to `base_price_per_night` if none match

---

## Guests (`/admin/guests`)

View and manage guest profiles. Guests are created automatically when a booking is submitted.

Each guest record shows:
- Contact info (email, phone, address, nationality)
- NID/Passport number
- Booking history

---

## Reviews (`/admin/reviews`)

Guest reviews require moderation before appearing on the public site.

- **Pending** — submitted but not yet visible to the public
- **Approved** — visible on the homepage and room pages
- Use the **Approve** button to publish a review

---

## Gallery (`/admin/gallery_albums`)

Organise photos into albums. Each album has:
- A name and description
- A `position` (display order)
- A `visible` flag

Add images to an album from the album detail page. Images are stored via Active Storage.

> In development (Replit), images are stored locally in `storage/`. In production, configure Active Storage to use an S3-compatible service.

---

## Facilities (`/admin/facilities`)

Manage the amenities/services shown on the public Facilities page. Each facility has:
- Name and description
- An icon name (emoji or icon class)
- A category: `comfort`, `services`, `connectivity`, `amenities`, `safety`, `dining`
- Position (display order) and `visible` flag

---

## Restaurant Menu (`/admin/menu_items`)

Manage the restaurant menu shown at `/menu`. Categories:
- `bengali` — Bengali Specialties
- `continental` — Continental
- `beverages` — Beverages
- `desserts` — Desserts
- `appetizers` — Appetizers

Toggle `available` to show/hide items without deleting them.

---

## Dining Reservations (`/admin/dining_reservations`)

Manage table reservation requests from the public `/dining_reservations/new` form.

Reservation statuses:
- `pending` → `confirmed` → `completed`
- Any status → `cancelled`

---

## Contact Inquiries (`/admin/contact_inquiries`)

Submissions from the `/contact` form. Mark as `read` or `replied` to track follow-up.

---

## Reports (`/admin/reports`)

- **Occupancy** — current room occupancy percentage
- **Revenue** — total revenue from confirmed/checked-in/checked-out bookings vs paid amount
- **Export Bookings** — CSV download of all bookings

---

## Settings (`/admin/settings`)

Key-value site configuration stored in the database. Editable without code changes:

| Key            | Example Value                            |
|----------------|------------------------------------------|
| `site_name`    | Mollika Inn                              |
| `site_phone`   | +880 1712 345678                         |
| `site_email`   | info@mollikainn.com                      |
| `site_address` | Dogachi, Boalia, Naogaon-6500, Bangladesh|

Access in code: `Setting["site_name"]`
