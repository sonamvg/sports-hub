require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module PodiumCircle
  class Application < Rails::Application
    config.load_defaults 8.1

    # Tournament payment fields were stored as plaintext before Active Record
    # Encryption was enabled on them. This lets existing plaintext rows be
    # read as-is instead of raising, and they're transparently re-encrypted
    # the next time the record is saved.
    config.active_record.encryption.support_unencrypted_data = true
  end
end
