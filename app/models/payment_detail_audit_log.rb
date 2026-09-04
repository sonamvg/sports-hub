class PaymentDetailAuditLog < ApplicationRecord
  belongs_to :tournament
  belongs_to :actor, class_name: "User", optional: true

  validates :changed_fields, presence: true
end
