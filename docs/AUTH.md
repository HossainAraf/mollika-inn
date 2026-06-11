# Mollika Inn — Authentication Guide

## Overview

Mollika Inn uses a **simple session-based authentication** system with a single admin account. There is no User model or database table for credentials — the admin email and password are stored as environment variables.

This is intentional: the hotel has one operator who manages everything through the admin panel.

---

## Admin Credentials

| Setting          | Value (default)          | Where configured              |
|------------------|--------------------------|-------------------------------|
| Email            | `admin@mollikainn.com`   | `ADMIN_EMAIL` env var         |
| Password         | `mollika2025`            | `ADMIN_PASSWORD` env var      |

> **Change these in production.** Update `ADMIN_EMAIL` and `ADMIN_PASSWORD` in the Replit Secrets tab (or your server's environment). The app picks them up on next request — no restart needed.

---

## How It Works

### The Authentication Concern

`app/controllers/concerns/authentication.rb`:

```ruby
module Authentication
  def authenticated?
    session[:admin_authenticated] == true
  end

  def require_authentication
    redirect_to new_session_path, alert: "Please sign in first." unless authenticated?
  end

  def start_session(email)
    reset_session          # prevents session fixation
    session[:admin_authenticated] = true
    session[:admin_email] = email
  end

  def end_session
    reset_session
  end
end
```

### The Admin Base Controller

All admin controllers inherit from `Admin::BaseController`:

```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin!
  layout "admin"

  private

  def require_admin!
    redirect_to new_session_path, alert: "Please sign in." unless authenticated?
  end
end
```

Any controller that does **not** inherit from `Admin::BaseController` is **public by default**.

### Login Flow

1. User visits `/admin` → redirected to `/session/new` (login form)
2. Submits email + password → `SessionsController#create`
3. Credentials compared with `ActiveSupport::SecurityUtils.secure_compare` (timing-safe)
4. On success: `start_session(email)` stores `session[:admin_authenticated] = true`
5. Redirect to `/admin` (dashboard)

### Logout

POST to `/session` with `_method=DELETE`, or use the sign-out button in the admin nav.

---

## Protecting New Controllers

Any new admin controller **must** inherit from `Admin::BaseController`:

```ruby
# CORRECT — protected
class Admin::MyNewController < Admin::BaseController
  def index
    # ...
  end
end

# WRONG — public (no auth check)
class Admin::MyNewController < ApplicationController
  # ...
end
```

---

## Session Security

- `reset_session` is called on login (prevents session fixation attacks)
- Rails' built-in cookie signing protects the session cookie
- Credentials compared with `secure_compare` (constant-time, prevents timing attacks)
- No sensitive data beyond `admin_authenticated: true` and `admin_email` is stored in the session

---

## Guest Portal (Phase 2)

The `guests/` namespace is set up in routes but not yet implemented. It will provide guests with a self-service portal to view and manage their own bookings. This uses separate auth logic from the admin panel.

---

## Changing Credentials

1. Go to the **Secrets** tab in Replit (or your `.env` / server environment)
2. Update `ADMIN_EMAIL` to the new email address
3. Update `ADMIN_PASSWORD` to a strong password
4. The change takes effect immediately — no redeploy required

There is no password reset flow. If you forget the admin password, update the `ADMIN_PASSWORD` env var directly.
