require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../models/india_setting'
require_relative '../lib/exporter'
require 'net/ftp'
require_relative '../../../concerns/game_modx/manager'

class Manager < Hamster::Harvester
  include GameModx::Manager

  def initialize
    super
    @debug    = commands[:debug]
    @pages    = 0
    @settings = IndiaSetting.pluck(:variable, :value).to_h { |key, value| [key.to_sym, value] }
    @keeper   = Keeper.new(@settings)
  end

  def export
    keeper.status = 'exporting'
    exporter      = Exporter.new(keeper)
    domen         = :indiaps
    csv           = exporter.make_csv(domen)
    file_name     = "#{keeper.run_id}_#{domen.to_s}_games.csv.gz"
    peon.put(file: file_name, content: csv)

    file_path    = "#{@_storehouse_}store/#{file_name}"
    gz_file_data = IO.binread(file_path)
    Hamster.send_file(gz_file_data, file_name)

    notify "Exporting finish!" if @debug
  end

  def download
    peon.move_all_to_trash
    puts 'The Store has been emptied.' if @debug
    peon.throw_trash(5)
    puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping PS_IN started' if @debug
    scraper = Scraper.new(keeper: keeper, settings: @settings)
    scraper.scrape_games_in
    notify "Scraping IN finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing PS_IN started' if @debug
    keeper.status = 'parsing'
    if commands[:lang]
      parse_save_genre_lang
      return
    end
    parse_save_main
    parse_save_genre_lang if keeper.count[:saved] > 0 || @settings[:day_all_lang_scrap].to_i == Date.current.day
    keeper.delete_not_touched
    cleared_cache = keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0
    notify "‼️ Deleted: #{keeper.count[:deleted]} old PS_IN games" if keeper.count[:deleted] > 0
    clear_cache if cleared_cache
    export if !keeper.saved.zero? || !keeper.updated.zero? || !keeper.updated_menu_id.zero?
    keeper.finish
    notify '👌 The PS_IN parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    if !cleared_cache && (!keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?)
      clear_cache
    end
  end

  private

  def parse_save_main
    run_id       = keeper.run_id
    list_pages   = peon.give_list(subfolder: "#{run_id}_games_in").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count = 0
    list_pages.each do |name|
      puts name.green if @debug
      file       = peon.give(file: name, subfolder: "#{run_id}_games_in")
      parser     = Parser.new(html: file)
      list_games = parser.parse_list_games_in
      parser_count += parser.parsed
      keeper.save_in_games(list_games)
      @pages += 1
    end
    message = make_message(parser_count)
    notify message if message.present?
  end

  def parse_save_genre_lang
    if @settings[:day_all_lang_scrap].to_i == Date.current.day && Time.current.hour < 12
      notify "⚠️ Day of parsing All PS_IN games without rus and with empty content!"
    end
    run_parse_save_lang
    notify "📌 Added language for #{keeper.count[:updated_lang]} PS_IN game(s)." unless keeper.count[:updated_lang].zero?
  end

  def make_message(parser_count)
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new PS_IN games;\n" unless keeper.count[:saved].zero?
    message << "✅ Restored: #{keeper.count[:restored]} PS_IN games;\n" unless keeper.count[:restored].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} PS_IN games;\n" unless keeper.count[:updated].zero?
    message << "✅ Skipped prices: #{keeper.count[:skipped]} PS_IN games;\n" unless keeper.count[:skipped].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} PS_IN games;\n" unless keeper.count[:updated_menu_id].zero?
    message << "✅ Parsed: #{@pages} pages, #{parser_count} PS_IN games." unless parser_count.zero?
    message
  end
end
