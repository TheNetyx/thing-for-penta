class AdminController < ApplicationController
  before_action :auth_admin

  def index # this is unused now.
    redirect_to manage_path
  end

  def manage
    @new_player = Player.new
    @players = Player.order(:team).order(:name)
    @round = Round.all.first

    @items = []
    Item.order(:name).each do |item|
      @items.push({
        name: item.name,
        count: [
          item.t1,
          item.t2,
          item.t3,
          item.t4,
          item.t5,
          item.t6
        ],
        id: item.identifier
      })
    end
    @scores = [
      @round.t1s,
      @round.t2s,
      @round.t3s,
      @round.t4s,
      @round.t5s,
      @round.t6s,
    ]
    @conflicts = get_conflicts

    @logs = ItemLog.all
  end


  # only the essentials for running a game:
  # > game map
  # > conflict detection and resolution
  # thats it.
  def manage_simple
    @round = Round.all.first
    @scores = [
      @round.t1s,
      @round.t2s,
      @round.t3s,
      @round.t4s,
      @round.t5s,
      @round.t6s,
    ]

    @conflicts = get_conflicts

    @logs = ItemLog.all
  end

  private
  def get_conflicts
    conflicts = []
    locations = []
    Player.order(:team).order(:name).each do |tp|
      locations.push({player: tp, locid: tp.xpos * 9 + tp.ypos}) if tp.alive
    end
    while locations.length > 0
      sameloc = [locations[0][:player]]
      locid = locations[0][:locid]
      todel = []

      (1..(locations.length - 1)).each do |i|
        if locations[i][:locid] == locid
          sameloc.push locations[i][:player]
          # dont delete the players yet to avoid messing with i and array indices
        end
      end

      if sameloc.length > 1
        conflicts.push({combatants: sameloc})
      end
      locations.each do |loc|
        if loc[:locid] == locid
          todel.push loc
        end
      end
      todel.each do |item|
        locations.delete item
      end
    end
    conflicts
  end
end
