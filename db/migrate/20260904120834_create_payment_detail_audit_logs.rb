class CreatePaymentDetailAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_detail_audit_logs do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string :changed_fields, null: false

      t.timestamps
    end
  end
end
