require_relative "boot"
require "rails/all"
require "csv"

Bundler.require(*Rails.groups)

module PodiumCircle
  class Application < Rails::Application
    config.load_defaults 8.1

    # This app is India-only (INR currency, Indian states/PIN codes/phone
    # formats throughout) — organizers, athletes, and academies all operate
    # in IST. Without this, Rails defaults `Time.zone` to UTC, so a
    # datetime-local input like a tournament's registration open/close time
    # (typed by the organizer in their own local clock, with no UTC offset
    # attached) gets cast and later displayed as if it were UTC — silently
    # shifting it by 5.5 hours from what everyone actually intended. Setting
    # this makes `Time.zone`/`Time.current` and every time-zone-aware
    # attribute read/write consistently in IST, matching the one time zone
    # every real user of this app is actually in. The database still stores
    # true UTC instants underneath (Rails' recommended default) — only the
    # Ruby-level interpretation/display zone changes.
    config.time_zone = "Kolkata"

    # Tournament payment fields were stored as plaintext before Active Record
    # Encryption was enabled on them. This lets existing plaintext rows be
    # read as-is instead of raising, and they're transparently re-encrypted
    # the next time the record is saved.
    config.active_record.encryption.support_unencrypted_data = true
  end
end
