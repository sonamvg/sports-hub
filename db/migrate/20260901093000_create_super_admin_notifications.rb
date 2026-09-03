class CreateSuperAdminNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :super_admin_notifications do |t|
      t.integer :kind, null: false
      t.integer :status, null: false, default: 0
      t.references :notifiable, polymorphic: true, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.datetime :dismissed_at
      t.text :message

      t.timestamps
    end

    add_index :super_admin_notifications, [:kind, :status]
    add_index :super_admin_notifications, :dismissed_at
  end
end
