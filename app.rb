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

  restaurant = {
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
          reply_message[:text] += "您可以輸入以下的指令：\n"
          reply_message[:text] += "\"吃什麼\"：查詢今日餐點 \n"
          reply_message[:text] += "\"點餐\"：開始點餐 \n"

        when '吃什麼'
          reply_message[:text] += " #{restaurant[:restaurant_name]} \n"
          restaurant[:restaurant_menu].each_key do |type|
            reply_message[:text] += "#{type} \n"
            restaurant[:restaurant_menu][type].each do |dish|
              reply_message[:text] += "#{dish} \n"
            end
            reply_message[:text] += "\n"
          end
        when '點餐'
          reply_message = {
            "type": "template",
            "thumbnailImageUrl": "https://www.google.com.tw/url?sa=i&rct=j&q=&esrc=s&source=images&cd=&cad=rja&uact=8&ved=0ahUKEwjK6KSAivTRAhUFjJQKHUz1BTIQjRwIBw&url=http%3A%2F%2Fwww.gigcasa.com%2Fcn%2Farticles%2F142997&psig=AFQjCNEFl8yM3w52weuFgifgQ5rAnqwqdg&ust=1486216472264092",
            "altText": "請選擇您的餐點種類",
            "template": {
                "type": "buttons",
                "title": "今天想吃點什麼？",
                "text": "點選您想吃的類別",
                "actions": [
                    {
                      "type": "postback",
                      "label": "水餃類",
                      "data": {id: event['message']['id'], type:"choseType", answer:"水餃類"}.to_json
                    },
                    {
                      "type": "postback",
                      "label": "餅類",
                      "data": {id: event['message']['id'], type:"choseType", answer:"餅類"}.to_json
                    }
                ]
            }
          }

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
    when Line::Bot::Event::Postback

      payload = JSON.parse(event['postback']['data'])

      case payload['type']
      when "choseType"
      message = {
        type: 'text',
        text: "#{payload['id']} 選擇了 #{payload['answer']}"
      }

      # message = {
      #   "type": "template",
      #   "altText": "選擇你的餐點數量",
      #   "template": {
      #       "type": "carousel",
      #       "columns": [
      #           {
      #             "thumbnailImageUrl": "https://example.com/bot/images/item1.jpg",
      #             "title": "this is menu",
      #             "text": "description",
      #             "actions": [
      #                 {
      #                     "type": "postback",
      #                     "label": "Buy",
      #                     "data": "action=buy&itemid=111"
      #                 },
      #                 {
      #                     "type": "postback",
      #                     "label": "Add to cart",
      #                     "data": "action=add&itemid=111"
      #                 },
      #                 {
      #                     "type": "uri",
      #                     "label": "View detail",
      #                     "uri": "http://example.com/page/111"
      #                 }
      #             ]
      #           },
      #           {
      #             "thumbnailImageUrl": "https://example.com/bot/images/item2.jpg",
      #             "title": "this is menu",
      #             "text": "description",
      #             "actions": [
      #                 {
      #                     "type": "postback",
      #                     "label": "Buy",
      #                     "data": "action=buy&itemid=222"
      #                 },
      #                 {
      #                     "type": "postback",
      #                     "label": "Add to cart",
      #                     "data": "action=add&itemid=222"
      #                 },
      #                 {
      #                     "type": "uri",
      #                     "label": "View detail",
      #                     "uri": "http://example.com/page/222"
      #                 }
      #             ]
      #           }
      #       ]
      #   }
      # }
      client.reply_message(event['replyToken'], message)
      when "choseDish"

      else
      end
    end
  end

  "OK"
end

end
