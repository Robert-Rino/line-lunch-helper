require 'sinatra'
require 'json'
require 'base64'
require 'line/bot'
require_relative 'models/configuration'
require_relative 'helpers/reply_of_command'

# Configuration Sharing Web Service
class ShareConfigurationsAPI < Sinatra::Base
  before do
    Configuration.setup
  end

  restaurant_0 = [
    {flavor: '排骨', price:'80'},
    {flavor: '雞腿', price:'100'},
    {flavor: '照燒', price:'80'},
    {flavor: '壽喜燒', price:'90'},
  ]

  restaurant_1 = [
    {flavor: '排骨麵', price:'80'},
    {flavor: '雞腿麵', price:'100'},
    {flavor: '照燒麵', price:'80'},
    {flavor: '壽喜燒麵', price:'120'},
  ]

  restaurant_list = [restautant_1,restautant_2]

  menu = restaurant_list[0]

  get '/?' do
    'ConfigShare web service is up and running at /api/v1'
  end

  get '/api/v1/?' do
    # TODO: show all routes as json with links
  end

  def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
  end

post '/callback' do
  body = request.body.read
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        res_message = event.message['text']
        reply_message = {
          type: 'text',
          text: ''
        }

        if res_message.strip[0] == '/'
          command = res_message.strip[1..-1]
          # case command
          # when 'shops'
          #   restautant_list.each_with_index do |restrant, index|
          #     reply_message[:text] += "#{index}. #{restrant} \n"
          #   end
          client.reply_message(event['replyToken'], ReplyOfCommand.call(command))
          # client.reply_message(event['replyToken'], reply_message)
        end

        menu.each_with_index do |dish, index|
          reply_message[:text] += "#{index}. #{dish[:flavor]} $#{dish[:price]} \n"
        end

        client.reply_message(event['replyToken'], reply_message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        message = {
          type: 'text',
          text: '謝謝分享 我現在還看不懂圖片和影片喔 :)'
        }
        client.reply_message(event['replyToken'], message)
      end
    # when Line::Bot::Event::Postback
    #
    #   payload = JSON.parse(event['postback']['data'])
    #   message = {
    #     type: 'text',
    #     text: "你選擇了 #{payload['ans']}"
    #   }
    #   client.reply_message(event['replyToken'], message)
    #   message_payload_string = redis.get payload['id']

    end
  end

  "OK"
end

end
