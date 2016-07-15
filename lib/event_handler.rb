class EventHandler
  def initialize(event, bot_id)
    @data = JSON.parse(event.data)
    @bot_id = bot_id
  end

  def command?
    just_text? && user_message? && @data['text'].strip.start_with?('halbot')
  end

  def just_text?
    subtype = @data['subtype'] if @data['subtype']
    text_subtypes = ['me_message']
    (subtype.nil? || text_subtypes.include?(subtype)) && user_message?
  end

  def text_edited?
    @data['subtype'] == 'message_changed' && user_message?
  end

  def user_message?
    @data['type'] == 'message' && @data['user'] && @data['user'] != @bot_id ||
      @data['subtype'] == 'message_changed'
  end

  def first_message?
    @data == {'type' => 'hello'}
  end

  def bot_joined_group_or_channel?
    return false unless @data['type'] == 'group_joined' || @data['type'] == 'channel_joined'
    @bot_id == @data['channel']['latest']['user']
  end

  def user_joined_group_or_channel?
    (@data['subtype'] == 'group_join' || @data['subtype'] == 'channel_join') && user_message?
  end

  def user_cursed?
    text = @data['text'] || @data['message']['text']
    /sh.?t|damn|f.?ck|cunt|\bass\b|asshole|whore|bastard|b.?tch|\bcock\b|slut|dick|pussy|fag|f.?ggot|nigg.?r|chink|wetback|nigga/i =~ text
  end
end
