require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.eager_load = false

  config.cache_classes = false
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.assets.quiet = true
end

