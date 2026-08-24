class Academy < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :athletes, dependent: :nullify

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :name, :city, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def visible_to_public?
    approved?
  end
end
