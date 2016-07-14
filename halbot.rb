require 'http'
require 'json'
require 'faye/websocket'
require 'eventmachine'

class Halbot
  attr_reader :id, :groups
  attr_accessor :connected

  def initialize(id)
    @id = id
    @connected = false
    @channels = []
    @groups = []
  end

  def greet(socket)
    all_channels.each do |channel|
      socket.send({ type: 'message',
                    channel: channel['id'],
                    text: 'I have come with great news! Welcome me!',
                    as_user: true
                  }.to_json
                 )
    end
  end

  def update_all_channels
    update_public_channels
    update_private_channels
  end

  def all_channels
    @channels + @groups
  end

  private

  def update_public_channels
    @channels = []
    channel_response = HTTP.get('https://slack.com/api/channels.list', params: { token: ENV['SLACK_BOT_TOKEN']})
    channels_data = JSON.parse(channel_response)
    channels_member = channels_data['channels'].select { |c| c['is_member'] }
    channels_member.each do |channel|
      @channels << { 'id'=> channel['id'], 'name'=> channel['name'] }
    end
  end

  def update_private_channels
    @groups = []
    groups_response = HTTP.get('https://slack.com/api/groups.list', params: { token: ENV['SLACK_BOT_TOKEN']})
    groups_data = JSON.parse(groups_response)
    groups_hash = groups_data['groups'].select { |c| c['is_group'] }
    groups_hash.each do |group|
      @groups << { 'id' => group['id'], 'name' => group['name'] }
    end
  end
end

slack_rtm_url = 'https://slack.com/api/rtm.start'
response = HTTP.get(slack_rtm_url, params: { token: ENV['SLACK_BOT_TOKEN']})

url = JSON.parse(response.body)['url']

# bot_id = JSON.parse(HTTP.get('https://slack.com/api/users.info', params: {token: ENV['SLACK_BOT_TOKEN']}))

halbot = Halbot.new('U1RJMG94Y')
halbot.update_all_channels

EventMachine.run do
  socket = Faye::WebSocket::Client.new(url)

  socket.on :open do |event|
    halbot.connected = true
    p [:open]
  end

  socket.on :message do |event|
    p JSON.parse(event.data)
    data = JSON.parse(event.data)

    if data == {'type' => 'hello'}
      halbot.connected = true
      halbot.greet(socket)
    end


    if data['type'] == 'message' && data['user'] && data['user'] != halbot.id
      socket.send({ type: 'message',
                    channel: data['channel'],
                    text: 'HELLO',
                    as_user: true
                  }.to_json
                 )
    end
  end

  socket.on :close do |event|
    socket = nil
    EventMachine.stop
  end
end
