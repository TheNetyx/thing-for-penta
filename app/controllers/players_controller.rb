class PlayersController < ApplicationController
  before_action :auth_admin, except: [:get_team, :update]
  before_action :auth_teamid, only: [:get_team, :update]
  # most of these dont have much form validation because i'm lazy and as
  # only the admin has access to these i'll just assume the admin knows
  # what will work and what will cause this thing to explode.
=begin
  def view
    @players = Player.all
  end
=end
  def create
    @player = Player.new(player_params)
    @player.xpos = GridConf::TEAM_BASES[@player.team - 1][:x]
    @player.ypos = GridConf::TEAM_BASES[@player.team - 1][:y]
    @player.alive = true
    if !@player.save
      flash[:notice] = []
      @player.errors.full_messages.each do |mesg|
        flash[:notice].push mesg
      end
    else
      flash[:notice] = ["Player added"]
    end
    redirect_back_or_to root_path
  end

  def kill # this can also revive.
    @p = Player.find_by(id: params[:playerid])
    if @p == nil
      flash[:notice] = ["Player does not exist"]
    else
      if @p.alive
        @p.alive = false
        @p.respawn_round = Round.first.round + 2
      else
        @p.respawn_round = Round.first.round + 1
      end
      if !@p.save
        flash[:notice] = []
        @p.errors.full_messages.each do |mesg|
          flash[:notice].push mesg
        end
      else
        flash[:notice] = ["Player status updated"]
      end
    end
    redirect_back_or_to root_path
  end

  def delete
    @p = Player.find_by(id: params[:playerid])
    if @p == nil
      flash[:notice] = ["Player does not exist"]
    else
      @p.destroy
      flash[:notice] = ["Player deleted"]
    end
    redirect_back_or_to root_path
  end

  def get_team
    @teamid = Integer params[:teamid]
    @data = []
    # if asking form team0 (admin), give all players
    @players = Player.where("team = '#{@teamid}'")
    @players.each do |p|
      @data.push p.attributes.slice("id", "team", "name", "xpos", "ypos", "alive")
    end

    render json: {data: @data}
  end

  def get_all
    @data = []
    @players = Player.order(:team)
    @players.each do |p|
      @data.push p.attributes.slice("id", "team", "name", "xpos", "ypos", "alive")
    end

    render json: {data: @data}
  end


  def update
    @teamid = Integer params[:teamid]
    @data = JSON.parse params[:data]

    flash[:notice] = []

    if Round.all.first["t#{@teamid}".to_sym]
      flash[:notice].push "already moved this round"
      redirect_back_or_to root_path and return
    end

    @data.each do |entry|
      @player = Player.find_by id: entry["id"]

      next if ((!@player) || (@player.team != @teamid) || (!TheGrid.valid_moves(@player).include?({x: entry["xpos"], y: entry["ypos"]})))
      @player[:xpos] = entry["xpos"]
      @player[:ypos] = entry["ypos"]
      if !@player.save
        @player.errors.full_messages.each do |mesg|
          flash[:notice].push(@player.name + ": " + mesg + ", position unchanged")
        end
      else
        flash[:notice].push(@player.name + ": position updated")
      end
    end

    @r = Round.all.first
    @r["t#{@teamid}".to_sym] = true
    @r.save
=begin
    # when all teams have moved
    if (@r[:t1] && @r[:t2] && @r[:t3] && @r[:t4] && @r[:t5] && @r[:t6])
    end
=end
    redirect_back_or_to root_path
  end

  private
  def player_params
    p = params.require(:player).permit(:name, :team, :xpos, :ypos, :alive)
  end
end
