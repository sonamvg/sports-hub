class Match < ApplicationRecord
  class NotReadyForResultError < StandardError; end

  belongs_to :tournament_category
  belongs_to :registration_one, class_name: "Registration", optional: true
  belongs_to :registration_two, class_name: "Registration", optional: true
  belongs_to :winner_registration, class_name: "Registration", optional: true
  belongs_to :next_match, class_name: "Match", optional: true

  enum :status, { pending: 0, bye: 1, completed: 2 }, default: :pending
  enum :medal, { no_medal: 0, gold: 1, silver: 2, bronze: 3 }, default: :no_medal
  enum :decision, { points: 0, rsc: 1, disqualification: 2, withdrawal: 3, no_show: 4 }, validate: { allow_nil: true }

  validates :round_number, :slot_position, numericality: { only_integer: true, greater_than: 0 }
  validates :next_match_slot, inclusion: { in: [ 1, 2 ] }, allow_nil: true
  validate :winner_must_be_a_participant

  def ready_for_result?
    pending? && registration_one_id.present? && registration_two_id.present?
  end

  def final_round?
    next_match_id.nil?
  end

  def semifinal?
    next_match&.final_round? || false
  end

  def loser_registration_id
    return if winner_registration_id.blank?

    [ registration_one_id, registration_two_id ].compact.find { |id| id != winner_registration_id }
  end

  def resolve_as_bye!(winner_registration_id:)
    transaction do
      update!(status: :bye, winner_registration_id: winner_registration_id, completed_at: Time.current)
      advance_winner!
    end
  end

  def record_result!(winner_registration_id:, decision:, score_data: {})
    raise NotReadyForResultError, "Match is not ready for a result" unless ready_for_result?
    raise NotReadyForResultError, "A winner is required" if winner_registration_id.blank?

    transaction do
      update!(
        winner_registration_id: winner_registration_id,
        decision: decision,
        score_data: score_data,
        status: :completed,
        completed_at: Time.current,
        medal: medal_for_outcome
      )
      advance_winner!
    end
  end

  private

  def medal_for_outcome
    return :gold if final_round?
    return :bronze if semifinal?

    :no_medal
  end

  def advance_winner!
    return if next_match_id.blank?

    attribute = next_match_slot == 1 ? :registration_one_id : :registration_two_id
    next_match.update!(attribute => winner_registration_id)
  end

  def winner_must_be_a_participant
    return if winner_registration_id.blank?

    unless [ registration_one_id, registration_two_id ].include?(winner_registration_id)
      errors.add(:winner_registration, "must be one of the two participants")
    end
  end
end
