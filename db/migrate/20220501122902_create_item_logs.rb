class CreateItemLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :item_logs do |t|
      t.string :message

      t.timestamps
    end
  end
end
