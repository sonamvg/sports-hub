Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.hosts << ENV.fetch("APP_HOST", "podiumcircle.com")
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "podiumcircle.com"),
    protocol: "https"
  }
  config.active_storage.service = :amazon
  config.active_support.report_deprecations = false
end
