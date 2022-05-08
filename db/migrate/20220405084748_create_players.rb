class CreatePlayers < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      t.string :name
      t.integer :xpos
      t.integer :ypos
      t.integer :team
      t.boolean :alive

      t.timestamps
    end
  end
end
