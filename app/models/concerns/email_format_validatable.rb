module EmailFormatValidatable
  extend ActiveSupport::Concern

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
