# Mollika Inn — Authentication Guide

## Overview

Mollika Inn uses a custom, session-based admin authentication flow. There is no database-backed `User` or admin table. The app validates the single admin login against credentials stored in either Rails credentials or environment variables.

This is a deliberately simple single-operator setup: one admin account controls the internal dashboard and management tools.

---

## Actual Admin Auth Implementation

### 1) Global controller behavior

[app/controllers/application_controller.rb](../app/controllers/application_controller.rb) includes the `Authentication` concern. That means all controllers are protected by default unless they explicitly skip the auth check.

```ruby
class ApplicationController < ActionController::Base
  include Authentication
end
```

The concern is defined in [app/controllers/concerns/authentication.rb](../app/controllers/concerns/authentication.rb):

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  private

  def authenticated?
    session[:admin_authenticated] == true
  end

  def require_authentication
    redirect_to new_session_path, alert: "Please sign in first." unless authenticated?
  end

  def start_session(email)
    reset_session
    session[:admin_authenticated] = true
    session[:admin_email] = email
  end

  def end_session
    reset_session
  end
end
```

Important: this is not a fully public-by-default setup. Public controllers must explicitly call `skip_before_action :require_authentication`, as seen in guest/public controllers such as [app/controllers/rooms_controller.rb](../app/controllers/rooms_controller.rb) and the booking flow.

### 2) Admin-only controllers

All admin pages inherit from [app/controllers/admin/base_controller.rb](../app/controllers/admin/base_controller.rb):

```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin!
  before_action :set_admin_notifications

  layout "admin"

  private

  def require_admin!
    unless authenticated?
      redirect_to new_session_path, alert: "Please sign in to access the admin panel."
    end
  end
end
```

This controller does two things:

- blocks unauthenticated access to every admin page
- loads admin notification data for the sidebar widget

### 3) Login route and form

The login flow is handled by [app/controllers/sessions_controller.rb](../app/controllers/sessions_controller.rb):

```ruby
class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def new
  end

  def create
    email = params[:email].to_s.strip
    password = params[:password].to_s

    if valid_admin_credentials?(email, password)
      start_session(email)
      redirect_to admin_root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    end_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
```

The actual sign-in page is [app/views/sessions/new.html.erb](../app/views/sessions/new.html.erb). It posts to the `session` resource and renders the login form at `/session/new`.

### 4) Credentials source

The credential check is:

```ruby
expected_email = Rails.application.credentials.dig(:admin, :email) || ENV["ADMIN_EMAIL"]
expected_password = Rails.application.credentials.dig(:admin, :password) || ENV["ADMIN_PASSWORD"]
```

Then it compares both values with `ActiveSupport::SecurityUtils.secure_compare`.

This means the app accepts credentials from either:

- Rails credentials: `Rails.application.credentials.dig(:admin, :email/password)`
- environment variables: `ADMIN_EMAIL`, `ADMIN_PASSWORD`

The app does not query a database table for the admin user.

---

## Full Admin Flow

1. A request hits an admin page under `/admin`.
2. [app/controllers/admin/base_controller.rb](../app/controllers/admin/base_controller.rb) runs `require_admin!`.
3. If `session[:admin_authenticated]` is not `true`, the user is redirected to `/session/new`.
4. The user submits email + password from the sign-in form.
5. [app/controllers/sessions_controller.rb](../app/controllers/sessions_controller.rb) validates those values against the configured admin credentials.
6. On success it calls `start_session(email)`, which does:
   - `reset_session`
   - `session[:admin_authenticated] = true`
   - `session[:admin_email] = email`
7. The user is redirected to `admin_root_path`, which resolves to the admin dashboard at `/admin`.
8. The admin dashboard renders under the Admin layout and includes the notification sidebar.

### Logout

The admin navbar calls the session resource with Turbo delete behavior. The `destroy` action clears the session and redirects back to the login page.

---

## Route Summary

From [config/routes.rb](../config/routes.rb):

- `/admin` → admin dashboard root
- `/session/new` → admin login form
- `POST /session` → login action
- `DELETE /session` → logout action

The admin namespace is separate from the guest/public app routes.

---

## Important Clarifications

### Not a database-backed auth model

There is an [app/models/admin.rb](../app/models/admin.rb) placeholder model, but it is not the active authentication mechanism. It is a lightweight data structure used as an alternative config holder, not a persisted admin record.

### No password reset flow

There is no admin password reset or self-service recovery flow in the app. If the password is forgotten, the credentials must be changed in the configured credential source (Rails credentials or environment variables).

### Public vs admin controllers

- Admin controllers: inherit from `Admin::BaseController`
- Public controllers: inherit from `ApplicationController` and usually call `skip_before_action :require_authentication`

This means the statement "all non-admin controllers are public by default" is not exactly true in the current codebase. Public controllers are public only because they explicitly skip the auth filter.

---

## Guest Portal

The `guests` namespace in [config/routes.rb](../config/routes.rb) is a separate guest portal area. It is not part of the admin authentication flow and uses its own, distinct guest-session logic. It is not the admin login flow.

---

## Credential Update Instructions

To change the admin credentials:

1. Update `ADMIN_EMAIL` and `ADMIN_PASSWORD` in the deployment environment, or set the values in Rails credentials.
2. Ensure the values are present before request handling.
3. The app reads the values on each request; environment variables are the simplest live source.

> Use a strong admin password in production. Do not leave the default values in a live environment.
