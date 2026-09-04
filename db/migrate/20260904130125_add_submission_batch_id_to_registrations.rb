class AddSubmissionBatchIdToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :registrations, :submission_batch_id, :string
    add_index :registrations, :submission_batch_id
  end
end
