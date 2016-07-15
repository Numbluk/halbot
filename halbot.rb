require 'http'
require 'json'
require 'faye/websocket'
require 'eventmachine'
require 'pry'

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

  def greet_on_connect
    greeting = 'I am connected once again!'
    all_channels.each do |channel|
      send_message(channel['id'], greeting)
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
    channel_response = HTTP.get('https://slack.com/api/channels.list', params: { token: 'xoxb-59965926720-PC63qyaEeG5pFrvU45qXmEJe' })
    channels_data = JSON.parse(channel_response)
    channels_member = channels_data['channels'].select { |c| c['is_member'] }
    channels_member.each do |channel|
      @channels << { 'id'=> channel['id'], 'name'=> channel['name'] }
    end
  end

  def update_private_channels
    @groups = []
    groups_response = HTTP.get('https://slack.com/api/groups.list', params: { token: 'xoxb-59965926720-PC63qyaEeG5pFrvU45qXmEJe'})
    groups_data = JSON.parse(groups_response)
    groups_hash = groups_data['groups'].select { |c| c['is_group'] }
    groups_hash.each do |group|
      @groups << { 'id' => group['id'], 'name' => group['name'] }
    end
  end
end

class EventHandler
  def initialize(event, bot_id)
    @data = JSON.parse(event.data)
    @bot_id = bot_id
  end

  def just_text?
    @data['subtype'].nil? && user_message?
  end

  def text_edited?
    @data['subtype'] == 'message_changed'
  end

  def user_message?
    @data['type'] == 'message' && @data['user'] && @data['user'] != @bot_id || @data['subtype'] == 'message_changed'
  end

  def first_message?
    @data == {'type' => 'hello'}
  end

  def bot_joined_group_or_channel?
    return false unless (@data['type'] == 'group_joined' || @data['type'] == 'channel_joined')
    @bot_id == @data['channel']['latest']['user']
  end

  def user_joined_group_or_channel?
    (@data['subtype'] == 'group_join' || @data['subtype'] == 'channel_join') && user_message?
  end

  def channel
    @data['channel']['id'] if @data['channel']
  end

  def user_cursed?
    text = @data['text'] || @data['message']['text']
    #handle cursing
  end
end
# {"type"=>"group_joined", "channel"=>{"id"=>"G116MMTK6", "name"=>"test", "is_group"=>true, "created"=>1460768372, "creator"=>"U0YL7G2SG", "is_archived"=>false, "is_mpim"=>false, "is_open"=>true, "last_read"=>"1468525273.000008", "latest"=>{"type"=>"message", "user"=>"U0YKM00SU", "text"=>"<@U1RJMG94Y>: asdf", "ts"=>"1468525273.000008"}, "unread_count"=>0, "unread_count_display"=>0, "members"=>["U0YKM00SU", "U11KUJ4KB", "U1RJMG94Y"], "topic"=>{"value"=>"", "creator"=>"", "last_set"=>0}, "purpose"=>{"value"=>"just for test purposes", "creator"=>"U0YL7G2SG", "last_set"=>1460768373}}}

# # a person joins the channel
# {"user"=>"U11KUJ4KB", "inviter"=>"U0YKM00SU", "user_profile"=>{"avatar_hash"=>"aa54bf5260fb", "image_72"=>"https://avatars.slack-edge.com/2016-05-23/45168883446_aa54bf5260fb6745c1d3_72.jpg", "first_name"=>"Lukas", "real_name"=>"Lukas Nimmo (350)", "name"=>"numbluk"}, "type"=>"message", "subtype"=>"group_join", "team"=>"T0YKP5Z9T", "text"=>"<@U11KUJ4KB|numbluk> has joined the group", "channel"=>"G1RJ33RST", "ts"=>"1468528787.000168"}


# # handle person joining group the bot is in
# # a message with a subtype of 'group_join'
# {
#   "type" => "message",
#   "subtype" => "group_join",
#   "channel" => "some_channel",
#   "user" => "username"
# }

# # handle person joining channel the bot is in
# # a message with a subtype of 'channel_join'
# {
#   "type" => "message",
#   "subtype" => "channel_join",
#   "channel" => "some_channel",
#   "user" => 'user_name'
# }

# # handle person sending a message of text
# # a message where event_data[:'subtype'].nil?
# {
#   "type" => 'message',
#   'channel' => 'some_channel',
#   'user' => 'some_user'
#   'text' => 'some_text'
# }

# # handle person editing a message of text
# # a message where event_data[:'subtype'] == 'message_changed'
# {
#   'type' => 'message',
#   'subtype' => 'message_changed',
#   'message' => { 'text' => 'changed text', 'edited' => {'user' => 'userid} }
# }
# {"type"=>"message", "message"=>{"type"=>"message", "user"=>"U11KUJ4KB", "text"=>"* edit", "edited"=>{"user"=>"U11KUJ4KB", "ts"=>"1468530537.000000"}, "ts"=>"1468529035.000176"}, "subtype"=>"message_changed", "hidden"=>true, "channel"=>"G1RJ33RST", "previous_message"=>{"type"=>"message", "user"=>"U11KUJ4KB", "text"=>"* and edit", "edited"=>{"user"=>"U11KUJ4KB", "ts"=>"1468530052.000000"}, "ts"=>"1468529035.000176"}, "event_ts"=>"1468530537.203567", "ts"=>"1468530537.000178"}


slack_rtm_url = 'https://slack.com/api/rtm.start'
oauth_response = HTTP.get(slack_rtm_url, params: { token: 'xoxb-59965926720-PC63qyaEeG5pFrvU45qXmEJe' })

access_token = JSON.parse(oauth_response.body)['url']
personal_bot_id = 'U1RUDT8M6'
launch_bot_id = 'U1RJMG94Y'
halbot = Halbot.new(personal_bot_id)
/shit|damn|fuck|cunt|\bass\b|asshole|whore|bastard|bitch|\bcock\b|slut|dick|pussy|fag|faggot|nigger|chink|wetback|nigga/i

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
    #   elsif event.user_command?
    #     halbot.handle_command(event_data)
      elsif event.just_text? || event.text_edited?
        # # handle person sending a message of text
        # # a message where event_data[:'subtype'].nil?
        # {
        #   "type" => 'message',
        #   'channel' => 'some_channel',
        #   'user' => 'some_user'
        #   'text' => 'some_text'
        # }

        # # handle person editing a message of text
        # # a message where event_data[:'subtype'] == 'message_changed'
        # {
        #   'type' => 'message',
        #   'subtype' => 'message_changed',
        #   'message' => { 'text' => 'changed text', 'edited' => {'user' => 'userid} }
        # }
        text = event_data['text'] || event_data['message']['text']
        user = event_data['user']
        puts 'WHY DID YOU CURSE' if event.user_cursed?
        # halbot.scold(event_data['user'], text) if event.user_cursed?
      end
    end

    # handle bot joining a channel
    if event.bot_joined_group_or_channel?
      halbot.greet_channel(event_data)
    end
  end

  socket.on :close do |event|
    socket = nil
    EventMachine.stop
  end
end
