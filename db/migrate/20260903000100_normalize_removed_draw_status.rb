class NormalizeRemovedDrawStatus < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE tournaments
      SET status = 2, updated_at = CURRENT_TIMESTAMP
      WHERE status = 9
    SQL
  end

  def down
    # The removed draw status no longer exists in the application.
  end
end
