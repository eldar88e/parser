require_relative '../models/sony_game_run'
require_relative '../models/sony_game_ua_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'

class ModelManager < Hamster::Keeper

  def run_last
    [SonyGameRun.last, SonyGameUaRun.last]
  end

  def report_games
    SonyGame.where(parent: [settings['parent_ps5'], settings['parent_ps4'], 21, 22])
  end
end
