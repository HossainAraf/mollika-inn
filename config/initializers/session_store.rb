# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: "_mollika_inn_session",
  secure: Rails.env.production?,
  same_site: :lax,
  httponly: true