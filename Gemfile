source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "bcrypt", "~> 3.1.7"
gem "bootsnap", require: false
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 1.2"
gem "rqrcode", "~> 3.0"
# Bundles the IANA time zone database in pure Ruby so config.time_zone
# resolves correctly regardless of whether the deployment OS/container has
# /usr/share/zoneinfo installed — the production Dockerfile's slim Debian
# base never explicitly installs the `tzdata` apt package, so this can't be
# assumed to be present there even though it happens to exist on macOS.
gem "tzinfo-data"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
end

group :development do
  gem "web-console"
end
