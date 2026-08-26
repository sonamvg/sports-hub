class RegistrationActionLog < ApplicationRecord
  belongs_to :registration
  belongs_to :actor, class_name: "User"

  validates :action, :to_status, presence: true
end
