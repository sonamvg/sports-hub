module ConsentRecordable
  extend ActiveSupport::Concern

  included do
    attr_accessor :terms_accepted, :data_sharing_consent, :require_consent

    before_validation :record_consent_acceptance
    validate :required_consents_must_be_accepted
  end

  private

  def record_consent_acceptance
    now = Time.current
    self.terms_accepted_at ||= now if accepted_consent_value?(terms_accepted)
    self.data_sharing_consent_accepted_at ||= now if accepted_consent_value?(data_sharing_consent)
  end

  def required_consents_must_be_accepted
    return unless accepted_consent_value?(require_consent)

    errors.add(:terms_accepted, "must be accepted") if terms_accepted_at.blank?
    errors.add(:data_sharing_consent, "must be accepted") if data_sharing_consent_accepted_at.blank?
  end

  def accepted_consent_value?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
