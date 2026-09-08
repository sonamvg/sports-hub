# Explicit session cookie security settings (rather than relying on Rails'
# implicit defaults, which are easy to lose track of across upgrades):
# - same_site: :lax blocks the cookie from being sent on cross-site requests
#   initiated by other sites (e.g. an <img>/<form> on a malicious page),
#   while still allowing normal top-level navigation to the app to work.
# - secure in production means the cookie is only ever sent over HTTPS;
#   combined with config.force_ssl, it's never sent in the clear.
Rails.application.config.session_store :cookie_store,
  key: "_podium_circle_session",
  same_site: :lax,
  secure: Rails.env.production?
