Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  get   "/play/:teamid",                to: "play#index",           as: :play

  get   "/admin",                       to: "admin#index",          as: :admin
  get   "/admin/manage",                to: "admin#manage",         as: :manage
  get   "/admin/manage-game",           to: "admin#manage_simple",  as: :manage_simple

  post  "/api/add-player",              to: "players#create",       as: :create_player
  post  "/api/kill-player/:playerid",   to: "players#kill",         as: :kill_player
  post  "/api/delete-player/:playerid", to: "players#delete",       as: :delete_player
  get   "/api/get-players/:teamid",     to: "players#get_team",     as: :get_players_by_team
  post  "/api/update-players/:teamid",  to: "players#update",       as: :update_players
  get   "/api/get-players-all",         to: "players#get_all",      as: :get_players_all

  get   "/api/round-number",            to: "rounds#get_round",     as: :get_round
  get   "/api/check-sub/:teamid",       to: "rounds#check_sub",     as: :submission_check
  post  "/api/start-game",              to: "rounds#start",         as: :start_game
  post  "/api/advance-round",           to: "rounds#advance",       as: :advance_round
  get   "/api/check-sub-all",           to: "rounds#check_sub_all", as: :check_sub_all

  post   "/api/use-item/:teamid",       to: "items#use",            as: :use_item
  get    "/api/check-items/:teamid",    to: "items#check",          as: :check_items
  post   "/api/add-item/:teamid",       to: "items#add",            as: :add_item
end
