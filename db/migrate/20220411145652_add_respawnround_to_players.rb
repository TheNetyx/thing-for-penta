class AddRespawnroundToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :respawn_round, :integer
  end
end
