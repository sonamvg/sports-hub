Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Redirect all traffic to HTTPS and mark cookies (including the session
  # cookie) Secure, so they're never sent over a plain HTTP connection.
  config.force_ssl = true
  config.hosts << ENV.fetch("APP_HOST", "podiumcircle.com")
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "podiumcircle.com"),
    protocol: "https"
  }
  config.active_storage.service = :amazon
  config.active_support.report_deprecations = false

  # Puma doesn't gzip responses on its own; without this every HTML, CSS,
  # and JS response goes over the wire uncompressed.
  config.middleware.use Rack::Deflater
end
