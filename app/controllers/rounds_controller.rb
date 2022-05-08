class RoundsController < ApplicationController
  before_action :auth_admin, only: [:start, :advance, :check_sub_all]
  before_action :auth_teamid, only: [:get_score, :check_sub]


  def get_round
    render json: {data: Round.first[:round]}
  end

  def get_score
    render json: {data: Round.first["t#{params[:teamid]}s".to_sym]}
  end

  def check_sub
    render json: {data: Round.first["t#{params[:teamid]}".to_sym]}
  end

  def check_sub_all
    @round = Round.first
    @data = [ # using (1..6).each and to_sym causes runtime errors for some reason
      @round.t1,
      @round.t2,
      @round.t3,
      @round.t4,
      @round.t5,
      @round.t6
    ]

    render json: {data: @data}
  end

  def start
    Round.all.each do |r|
      r.destroy
    end
    @game = Round.new
    @game.round = 1

    @game.t1 = false
    @game.t2 = false
    @game.t3 = false
    @game.t4 = false
    @game.t5 = false
    @game.t6 = false

    @game.t1s = 0
    @game.t2s = 0
    @game.t3s = 0
    @game.t4s = 0
    @game.t5s = 0
    @game.t6s = 0

    @game.state = RoundsConf::STATE_ACCEPT_MOVES
    @game.save

    # set up items
    Item.all.each do |item|
      item.delete
    end
    ItemConf::ITEMS.each do |item|
      new_item = Item.new
      new_item.identifier = item[:identifier]
      new_item.name = item[:name]
      new_item.fields = item[:fields]
      new_item.t1 = 0
      new_item.t2 = 0
      new_item.t3 = 0
      new_item.t4 = 0
      new_item.t5 = 0
      new_item.t6 = 0
      new_item.save
    end

    redirect_back_or_to root_path
  end

  def advance
    @game = Round.all.first

    if @game[:state] == RoundsConf::STATE_CONFLICTING
      # conflict state -> move state
      @game.state = RoundsConf::STATE_ACCEPT_MOVES
      # check for remaining conflicts - do not allow admin overriding
      # this probably isnt a very efficient way of doing things.
      @locations = []
      Player.all.each do |p|
        @locations.push({x: p.xpos, y: p.ypos}) if p.alive
      end
      if @locations.detect{ |e| @locations.count(e) > 1 } && ! all_same_team(@locations)
        flash[:notice] = ["unresolved conflicts"]
        redirect_back_or_to root_path and return
      end
      # calculate scores
      @scores = [0, 0, 0, 0, 0, 0]
      GridConf::CHECKPOINTS.each do |cp|
        Player.all.each do |p|
          if (cp[:x] == p.xpos) && (cp[:y] == p.ypos)
            @scores[p.team - 1] += GridConf::CP_POINTS if p.alive
            break
          end
        end
      end

      GridConf::SUPER_CHECKPOINTS.each do |cp|
        Player.all.each do |p|
          if (cp[:x] == p.xpos) && (cp[:y] == p.ypos)
            @scores[p.team - 1] += GridConf::SUPER_CP_POINTS if p.alive
            break
          end
        end
      end

      GridConf::TEAM_BASES.each do |cp|
        Player.all.each do |p|
          if (cp[:x] == p.xpos) && (cp[:y] == p.ypos) && ((GridConf::TEAM_BASES.find_index cp) + 1 != p.team)
            # index of @scores and GridConf::TEAM_BASES are all 1 less than te teamid
            @scores[GridConf::TEAM_BASES.find_index cp] -= GridConf::ENEMY_IN_BASE_PENALTY if p.alive
            break
          end
        end
      end
      # this is probably not the best way to do this, but somehow
      # doing clever shit causes 'cannot coerce nil to float' errors
      # so im doing it the retarded way
      @game.t1s += @scores[0]
      @game.t2s += @scores[1]
      @game.t3s += @scores[2]
      @game.t4s += @scores[3]
      @game.t5s += @scores[4]
      @game.t6s += @scores[5]

      @game.round += 1
      @game.t1 = false
      @game.t2 = false
      @game.t3 = false
      @game.t4 = false
      @game.t5 = false
      @game.t6 = false

      # revive dead people
      Player.where("respawn_round = ?", @game.round).each do |p|
        p.alive = true
        p.xpos = GridConf::TEAM_BASES[p.team - 1][:x]
        p.ypos = GridConf::TEAM_BASES[p.team - 1][:y]
        p.save
      end

      # items take effect here.
      ItemLog.destroy_all
      # creating a model isn't the most elegant solution, but it is a solution
      ItemRequest.where("processed = ?",  false).each do |req|
        self.class.process req[:team], req[:item], req[:targetcell], req[:targetplayer]
        req.processed = true
        req.save
      end
    else
      # move state -> conflict state

      @game.state = RoundsConf::STATE_CONFLICTING
      @game.t1 = true
      @game.t2 = true
      @game.t3 = true
      @game.t4 = true
      @game.t5 = true
      @game.t6 = true
    end
    @game.save
    redirect_back_or_to root_path
  end

  private
  def all_same_team arr
    if arr.length == 0
      return true
    end
    team = arr[0][:team]
    arr.each do |item|
      if item[:team] != team
        return false
      end
    end
    true
  end

  # processes usage of items
  def self.process t, i, c, p
    case i

    # bomb
    when 0
      kills = 0
      coords = c.split "-"
      players = Player.where("xpos = ?", coords[1].to_i).where("ypos = ?", coords[2].to_i)
      players.each do |p|
        p.alive = false
        p.respawn_round = Round.first[:round] + 2
        kills += 1 if p.save
      end
      add_item_log "team #{t} bombed #{c}, killing #{kills}"

    # locator
    when 1
      coords = c.split "-"
      count = Player.where("xpos = ?", coords[1].to_i).where("ypos = ?", coords[2].to_i).count
      add_item_log "team #{t} revealed #{count} enemies on square #{c}"

    # instant respawn is number 2, skip

    # minus points card
    when 3
      coords = c.split "-"
      team = GridConf::TEAM_BASES.index({x: coords[1].to_i, y: coords[2].to_i}) + 1
      round = Round.first
      round["t#{team}s".to_sym] -= 5
      round.save
      add_item_log "team #{t} used minus points card on team #{team}"

    # teleporter
    when 4
      coords = c.split "-"
      player = Player.find p
      player.xpos = coords[1].to_i
      player.ypos = coords[2].to_i
      player.save
      add_item_log "team #{t} teleported #{player[:name]} to #{c}"
    else
      add_item_log "ERR: team #{t} used an invalid item"
    end
  end
end

def add_item_log message
  i = ItemLog.new
  i[:message] = message
  i.save
end