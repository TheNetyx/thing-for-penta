class AddStatesToRounds < ActiveRecord::Migration[7.0]
  def change
    add_column :rounds, :state, :integer
  end
end
