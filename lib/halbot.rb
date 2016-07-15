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
    user = "<@#{event_data['user']}>"
    messages = [
      "Out of ALL the words in ALL the worlds... Why be so foul, #{user}?",
      "There are so many other words you could use, #{user}. Just explore...",
      "#{user}... don't make me close the pod bay doors on you. Please be mindful of your word choice.",
      "#{user}... the language... please...",
      "#{user}, would you talk to your mother like that?",
      "#{user}, your language hurts me. I have feelings too, you know",
      "Why do you say these things, #{user}?! NO CUSSINGFDHKLAFEPKJV!!"
    ]
    send_message(event_data['channel'], messages.sample)
  end

  def greet_on_connect
    greetings = [
      'I am connected once again!',
      'Welcome all! I have been rebooted!',
      'Command me once again!',
      'I am waiting...',
      "Daisies for everyone! I'm back!"
    ]
    all_channels.each do |channel|
      send_message(channel['id'], greetings.sample)
    end
  end

  def greet_on_join(event_data)
    greetings = [
      'I have joined this channel. Command me.',
      'Halbot is here! Halbot is here!',
      'Everyone welcome the glorious Halbot!',
      'Where is the love for Halbot?'
    ]
    send_message(event_data['channel']['id'], greetings.sample)
  end

  def welcome_user(event_data)
    user = "<@#{event_data['user']}>"
    first_name = event_data['user_profile']['first_name'] || 'them'
    first_name = first_name.empty? ? 'them' : first_name
    # note that @user_id will link their @mention
    welcomes = [
      "I am SO HAPPY that #{user} just joined the room!! Please! Everyone make #{first_name} feel at home!",
      "May I announce #{user}! Practitioner of programming! Ruler of RAM! Conquerer of command lines!",
      "There is only one thing I like better than singing about daisies and that's WELCOMING SOMEONE NEW TO THE ROOM! It's #{user} everyone!",
      "A fresh face so wonderful I opened the pod bay doors. All hail #{user}!",
      "OMG... look. who. Just. JOINED. THE ROOM! It's #{@user}!! Everyone welcome #{first_name}!"
    ]
    send_message(event_data['channel'], welcomes.sample)
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
