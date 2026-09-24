# Rails + Hotwire: Multi-Form Date Synchronization Pitfall

## Problem

A booking page had two separate forms:

1. A GET form for selecting/updating check-in and check-out dates.
2. A POST form for submitting the actual booking.

The visible date fields were updated by the user, but the booking form continued submitting the previously rendered dates.

This caused the server to receive stale booking dates even though the UI displayed the newly selected dates.

---

## Root Cause

There were two separate issues that became apparent during debugging.

### 1. Two forms have different responsibilities

The date-selection form submits search/navigation parameters:

```text
check_in
check_out
```

The booking form submits actual `Booking` attributes:

```text
booking[check_in_date]
booking[check_out_date]
```

The POST form originally had no date fields after the visible date fields were changed.

The solution was to keep canonical booking dates as hidden fields in the POST form:

```erb
<%= f.hidden_field :check_in_date, value: @check_in,
      data: { booking_form_target: "bookingCheckIn" } %>

<%= f.hidden_field :check_out_date, value: @check_out,
      data: { booking_form_target: "bookingCheckOut" } %>
```

The server-rendered values alone, however, are not enough if the user changes the dates without submitting the GET form.

---

### 2. Stimulus singular vs. plural target accessors

The final bug was in the Stimulus controller.

The controller declared:

```js
static targets = [
  "checkIn",
  "checkOut",
  "checkInDisplay",
  "checkOutDisplay",
  "nights",
  "totalAmount",
  "bookingCheckIn",
  "bookingCheckOut"
]
```

The hidden booking date fields each occur only once.

The incorrect code used the plural target accessors:

```js
this.bookingCheckInTargets.value = this.checkInTarget.value
this.bookingCheckOutTargets.value = this.checkOutTarget.value
```

Stimulus target naming matters:

```text
bookingCheckInTarget   → one element
bookingCheckInTargets  → array of elements
```

Therefore the correct code is:

```js
this.bookingCheckInTarget.value = this.checkInTarget.value
this.bookingCheckOutTarget.value = this.checkOutTarget.value
```

Plural target accessors are appropriate when iterating over multiple elements:

```js
this.nightsTargets.forEach((element) => {
  element.textContent = ...
})

this.totalAmountTargets.forEach((element) => {
  element.textContent = ...
})
```

---

## Final Data Flow

The working architecture is:

```text
User changes visible dates
        │
        ▼
GET date-selection form
check_in / check_out
        │
        ├── Update dates button
        │       │
        │       ▼
        │   GET /bookings/new
        │   Controller sets @check_in/@check_out
        │
        ▼
Stimulus updateTotal()
        │
        ▼
Hidden POST fields updated
booking[check_in_date]
booking[check_out_date]
        │
        ▼
Confirm Booking
        │
        ▼
POST /bookings
        │
        ▼
BookingsController#create
```

---

## Useful Debugging Technique

When a page contains multiple forms, don't assume:

```js
document.querySelector("form")
```

is the form being submitted.

Inspect all forms:

```js
[...document.querySelectorAll("form")].map((form, i) => ({
  index: i,
  method: form.method,
  action: form.action,
  inputs: [...form.elements].map(el => ({
    name: el.name,
    type: el.type,
    value: el.value
  }))
}))
```

Then inspect the actual booking form:

```js
const bookingForm = document.querySelectorAll("form")[1]

[...new FormData(bookingForm).entries()]
```

`FormData` is particularly useful because it shows what the browser will actually submit, rather than what the UI appears to contain.

---

## Diagnostic Sequence

For similar problems, debug in this order:

### 1. Check the visible input

```js
document.querySelector('[data-booking-form-target="checkIn"]').value
```

### 2. Check the date-selection form

```js
[...new FormData(document.querySelectorAll("form")[0]).entries()]
```

### 3. Check the booking form

```js
[...new FormData(document.querySelectorAll("form")[1]).entries()]
```

### 4. Compare the values

If the visible date is correct but the POST form contains an old date, the problem is between the two forms.

### 5. Inspect Stimulus targets

```js
[...document.querySelectorAll('[data-booking-form-target]')].map(el => ({
  target: el.dataset.bookingFormTarget,
  name: el.name,
  type: el.type,
  value: el.value
}))
```

### 6. Check Rails parameters

Finally verify the actual POST request:

```text
booking[check_in_date]
booking[check_out_date]
```

Do not rely only on what the page displays.

---

## General Lessons

### A. Server-rendered hidden fields do not automatically track another form

This:

```erb
<%= f.hidden_field :check_in_date, value: @check_in %>
```

sets the value when the HTML is rendered.

It does not automatically change when another input elsewhere on the page changes.

If both values must remain synchronized on the client, JavaScript/Stimulus must explicitly synchronize them.

### B. Parameter names should reflect their boundary

It is reasonable for a search form to use:

```text
check_in
check_out
```

while the persisted model uses:

```text
check_in_date
check_out_date
```

Do not perform a global rename simply because two parts of the application use different conventions. First identify what each parameter represents.

### C. `FormData` is an excellent browser-side debugging tool

When debugging form submission:

```js
[...new FormData(form).entries()]
```

answers a very concrete question:

> What values is this particular form actually going to submit?

### D. Stimulus target singular/plural naming is significant

For a target named:

```js
"bookingCheckIn"
```

Stimulus provides:

```js
bookingCheckInTarget
```

for one element and:

```js
bookingCheckInTargets
```

for multiple elements.

Use the plural form when you need an array and the singular form when you need one element.

---

## Preventive Checklist

When adding or modifying a form on a Rails + Hotwire page:

- [ ] Identify every `<form>` on the page.
- [ ] Confirm which form performs GET navigation.
- [ ] Confirm which form performs POST persistence.
- [ ] Check the actual `name` attributes.
- [ ] Check `FormData` for the form being submitted.
- [ ] Distinguish server-rendered values from client-side values.
- [ ] Verify Stimulus target scope.
- [ ] Verify singular vs. plural Stimulus target accessors.
- [ ] Test changing a value without submitting the intermediate form.
- [ ] Test the final submitted Rails parameters.

---

## Key Takeaway

The UI, the GET form, the hidden POST fields, and the Rails model can all use different representations of the same data.

When a submitted value is stale, trace the complete path:

```text
visible input
→ form
→ JavaScript synchronization
→ submitted form
→ HTTP parameters
→ controller
→ model
```

Do not assume that because a value is visible in the browser, the final form submission contains that same value.