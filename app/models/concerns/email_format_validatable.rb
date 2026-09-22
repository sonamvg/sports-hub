module EmailFormatValidatable
  extend ActiveSupport::Concern

  # URI::MailTo::EMAIL_REGEXP allows a domain with no dot at all (e.g.
  # "user@test"), which can never be a real, deliverable address. This is
  # that same regex with the domain's trailing "(?:\.label)*" (zero or more)
  # tightened to "+" (one or more), so at least one dot — and therefore a
  # TLD — is required.
  STRICT_EMAIL_REGEXP = /\A[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+\z/

  # Domains that are syntactically valid emails but never a real registrant
  # (documentation placeholders, disposable/throwaway inboxes). Blocking these
  # catches "test@test.com" / "someone@example.com" style junk that the
  # standard email format regex happily accepts. The ".test" TLD is
  # deliberately NOT included here — it's reserved by RFC 2606 for exactly
  # this kind of non-production use and is what this app's own test suite
  # uses for its fake addresses.
  PLACEHOLDER_EMAIL_DOMAINS = %w[
    example.com example.org example.net example.edu
    test.com test.org test.net test.io
    mailinator.com yopmail.com guerrillamail.com trashmail.com
    tempmail.com temp-mail.org 10minutemail.com throwawaymail.com
    fakeinbox.com getnada.com dispostable.com sharklasers.com
  ].freeze

  class_methods do
    def rejects_placeholder_email(attribute, **options)
      validate(**options) { reject_placeholder_email_domain(attribute) }
    end
  end

  private

  def reject_placeholder_email_domain(attribute)
    value = send(attribute).to_s
    return if value.blank?

    domain = value.rpartition("@").last.downcase
    return unless EmailFormatValidatable::PLACEHOLDER_EMAIL_DOMAINS.include?(domain)

    errors.add(attribute, "must be a real email address, not a placeholder or test domain")
  end
end
