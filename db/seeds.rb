#!/usr/bin/env ruby
# This command will automatically be run when you run "rails" with Rails 3 gems installed from the root of your application.

GAME_DATA = '/app/data/games.pgn'

def get_chess()
  game = Game.find_by(name:"Chess")
  if (game.nil?)
    game = Game.create(name:"Chess", rating_type: "elo", allow_ties: true, max_number_of_teams: 2, max_number_of_players_per_team: 1, min_number_of_teams: 2, min_number_of_players_per_team: 1 )
  end
  return game
end

def get_or_find_player(name)
  player = Player.find_by(name: name)
  if (player.nil?)
    email = name.gsub(/[^a-z]/i, '').downcase + '@benon.com'
    player = Player.new(name: name, email: email)
    player.save
  end
  return player
end

def add_result(white, black, result)
  game = get_chess()
  if result == '1-0'
    ResultService.create(game, teams: { "0" => {players: [white.id]}, "1" => {players: [black.id]} })
  elsif result == '0-1'
    ResultService.create(game, teams: { "0" => {players: [black.id]}, "1" => {players: [white.id]} })
  else
    ResultService.create(game, teams: { "0" => {players: [white.id], relation: 'ties'}, "1" => {players: [black.id]} })
  end
end

white_name = nil
black_name = nil
result = nil

File.open(GAME_DATA).each { |line|

  if line =~ /White.*"([^"]*)"/
    white_name = $1
  elsif line =~ /Black.*"([^"]*)"/
    black_name = $1
  elsif line =~ /Result.*"([^"]*)"/
    result = $1

    white_player = get_or_find_player(white_name)
    black_player = get_or_find_player(black_name)

    add_result(white_player, black_player, result)

    white_player = nil
    black_player = nil
    white_name = nil
    black_name = nil
    result = nil
  end
}

# stretch out the ratings
RatingHistoryEvent.all.sort_by{ |k| k.id }.reverse.each_with_index { |result, idx| result.update(created_at: DateTime.now - idx,updated_at: DateTime.now - idx)}
