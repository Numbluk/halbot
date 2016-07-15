require 'http'
require 'json'
require 'faye/websocket'
require 'eventmachine'
require 'pry'

require_relative './lib/halbot'
require_relative './lib/event_handler'

slack_rtm_url = 'https://slack.com/api/rtm.start'
oauth_response = HTTP.get(slack_rtm_url, params: { token: ENV['SLACK_BOT_TOKEN'] })

access_token = JSON.parse(oauth_response.body)['url']
personal_bot_id = 'U1RUDT8M6'
launch_bot_id = 'U1RJMG94Y'
halbot = Halbot.new(launch_bot_id)

EventMachine.run do
  socket = Faye::WebSocket::Client.new(access_token)

  socket.on :open do |event|
    halbot.update_all_channels
    halbot.connected = true
    halbot.socket = socket
    p [:open]
  end

  socket.on :message do |msg|
    p JSON.parse(msg.data)
    event_data = JSON.parse(msg.data)
    event = EventHandler.new(msg, halbot.id)

    if event.first_message?
      halbot.connected = true
      halbot.greet_on_connect
    end

    # handle user messages
    if event.user_message?

      if event.user_joined_group_or_channel?
        halbot.welcome_user(event_data)
      elsif event.command?
      event.user_cursed? ? halbot.scold(event_data) : halbot.execute(event_data)
      elsif event.just_text? || event.text_edited?
        halbot.scold(event_data) if event.user_cursed?
      end
    end

    # handle bot joining a channel
    if event.bot_joined_group_or_channel?
      halbot.greet_on_join(event_data)
    end
  end

  socket.on :close do |event|
    halbot.connected = false
    socket = nil
    EventMachine.stop
  end
end
