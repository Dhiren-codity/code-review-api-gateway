Brakeman.configure do |config|
  config.skip_checks = [
    "CheckBasicAuth",
    "CheckCrossSiteScripting",
    "CheckCSRF",
    "CheckForgerySetting"
  ]
end

