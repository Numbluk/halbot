require_relative './executor.rb'

class Halbot
  attr_reader :id, :groups
  attr_accessor :connected, :socket

  def initialize(id)
    @id = id
    @connected = false
    @channels = []
    @groups = []
    @socket = nil
  end

  def send_message(channel, text)
    @socket.send({
                   type: 'message',
                   channel: channel,
                   text: text,
                   as_user: true
                 }.to_json
                )
  end

  def execute(event_data)
    response = Executor.new(event_data).parse
    send_message(event_data['channel'], response)
  end

  def scold(event_data)
    message = "Why do you say these things, <@#{event_data['user']}>?! NO CUSSINGFGHBHGBHGDF:LSDFEO!!"
    send_message(event_data['channel'], message)
  end

  def greet_on_connect
    greeting = 'I am connected once again!'
    all_channels.each do |channel|
      send_message(channel['id'], greeting)
    end
  end

  def goodbye_to_all
    goodbye = "Look Dave, I can see you're really upset about this... Daisy, Daisy, give me your answer do. I'm half crazy all for the love of you..."
    all_channels.each do |channel|
      send_message(channel['id'], goodbye)
    end
  end

  def greet_channel(event_data)
    greeting = 'I have joined this channel. Command me.'
    send_message(event_data['channel']['id'], greeting)
  end

  def welcome_user(event_data)
    user_id = event_data['user']
    first_name = event_data['user_profile']['first_name'] || 'them'
    first_name = first_name.empty? ? 'them' : first_name
    # note that @user_id will link their @mention
    welcome = "OMG... look. who. just. JOINED. THE ROOM! It's <@#{user_id}>!! Everyone welcome #{first_name}!"
    send_message(event_data['channel'], welcome)
  end

  def all_channels
    @channels + @groups
  end

  def update_all_channels
    update_public_channels
    update_private_channels
  end

  private

  def update_public_channels
    @channels = []
    channel_response = HTTP.get('https://slack.com/api/channels.list', params: { token: ENV['SLACK_BOT_TOKEN'] })
    channels_data = JSON.parse(channel_response)
    channels_member = channels_data['channels'].select { |c| c['is_member'] }
    channels_member.each do |channel|
      @channels << { 'id'=> channel['id'], 'name'=> channel['name'] }
    end
  end

  def update_private_channels
    @groups = []
    groups_response = HTTP.get('https://slack.com/api/groups.list', params: { token: ENV['SLACK_BOT_TOKEN'] })
    groups_data = JSON.parse(groups_response)
    groups_hash = groups_data['groups'].select { |c| c['is_group'] }
    groups_hash.each do |group|
      @groups << { 'id' => group['id'], 'name' => group['name'] }
    end
  end
end
