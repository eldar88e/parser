require_relative './application_record'

class SonyGameAdditional < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_ADDITIONAL']

  belongs_to :sony_game, foreign_key: 'id'
end
