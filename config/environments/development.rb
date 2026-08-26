Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.action_controller.perform_caching = false
  config.active_storage.service = :local
  config.assets.quiet = true
end
