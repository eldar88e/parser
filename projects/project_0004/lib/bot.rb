require_relative 'keeper'

class Bot < Hamster::Harvester
  def initialize(*_)
    super
    @keeper = Keeper.new
  end

  def run
    Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
      bot.listen do |message|
        if message.text == 'run_last'
          last = run_last
          bot.api.send_message(chat_id: message.chat.id, text: last)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Не верные данные!\n #{message.text}")
        end
      end
    end
  end

  private

  attr_reader :keeper

  def run_last
    keeper.run_last.status
  end
end