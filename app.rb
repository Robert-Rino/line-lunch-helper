require 'sinatra'
require 'json'
require 'base64'
require 'line/bot'
require_relative 'models/configuration'

# Configuration Sharing Web Service
class ShareConfigurationsAPI < Sinatra::Base
  before do
    Configuration.setup
  end

  reataurant = {
    restaurant_name: '周胖子餃子館',
    restaurant_menu: {
      水餃類: ['豬肉水餃 $7', '牛肉水餃 $7', '玉米水餃 $8', '素蒸餃 $8'],
      餅類: ['蔥油餅 $35', '牛肉捲餅 $90', '豬肉捲餅 $90']
    }
  }


  # menu = [
  #   {flavor: '排骨', price:'80'},
  #   {flavor: '雞腿', price:'100'},
  #   {flavor: '照燒', price:'80'},
  #   {flavor: '壽喜燒', price:'90'},
  # ]

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

        case event.message['text']
        when 'help'
          reply_message[:text] = "
          您可以輸入以下的指令：\n
          \"吃什麼\" ：查詢今日餐點
          \"點餐\" ： 開始點餐
          "
        when '吃什麼'
          reataurant['restaurant_menu'].each_key do |type|
            reply_message[:text] += "#{type} \n"
            reataurant['restaurant_menu'][type].each do |dish|
              reply_message[:text] += "#{dish} \n"
            end
            reply_message[:text] += "\n"
          end
        when '開始點餐'

        else
          reply_message[:text] = '嗨～我是便當小幫手,我還看不懂您指令，你可以輸入help查詢我看得懂的指令喔 ！'
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
