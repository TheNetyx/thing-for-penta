class Player < ApplicationRecord
  validate :pos_validation

  validates :name, presence: true
  validates :team, inclusion: {in: (1..PlayerConf::NUM_TEAMS), message: "is invalid"}
  validates :alive, inclusion: {in: [ true, false ], message: "is not defined"}

  private
  def pos_validation
    errors.add(:position, "is invalid") unless GridConf::VALID_SPACES.include?({x: xpos, y:ypos})
  end
end
