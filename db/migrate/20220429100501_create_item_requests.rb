class CreateItemRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :item_requests do |t|
      t.integer :team
      t.integer :item
      t.string :targetcell
      t.integer :targetplayer
      t.boolean :processed

      t.timestamps
    end
  end
end
