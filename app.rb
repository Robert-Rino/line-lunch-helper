require 'sinatra'
require 'json'
require 'base64'
require 'line/bot'
require 'httparty'
require_relative 'models/configuration'

# Configuration Sharing Web Service
class ShareConfigurationsAPI < Sinatra::Base
  before do
    Configuration.setup
  end

  restaurant = {
    restaurant_name: '周胖子餃子館',
    restaurant_menu: {
      水餃類: {豬肉水餃: 7, 牛肉水餃: 7, 玉米水餃: 8, 素蒸餃: 8},
      餅類: {蔥油餅: 35, 牛肉捲餅: 90, 豬肉捲餅: 90}
    }
  }

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

        case event.message['text'].downcase
        when 'help'
          reply_message[:text] += "您可以輸入以下的指令：\n"
          reply_message[:text] += "\"吃什麼\"：查詢今日餐點 \n"
          reply_message[:text] += "\"點餐\"：開始點餐 \n"

        when '吃什麼'
          reply_message[:text] += " #{restaurant[:restaurant_name]} \n"
          restaurant[:restaurant_menu].each_key do |type|
            reply_message[:text] += "#{type} \n"
            restaurant[:restaurant_menu][type].each_key do |dish|
              reply_message[:text] += "#{dish} $#{restaurant[:restaurant_menu][type][dish]} \n"
            end
            reply_message[:text] += "\n"
          end
        when '點餐'
          reply_message = {
            "type": "template",
            "altText": "請選擇您的餐點種類",
            "template": {
                "type": "buttons",
                "title": "今天想吃點什麼？",
                "text": "點選您想吃的類別",
                "actions": [
                    {
                      "type": "postback",
                      "label": "水餃類",
                      "data": {id: event['source']['userId'], type:"choseType", answer:"水餃類"}.to_json
                    },
                    {
                      "type": "postback",
                      "label": "餅類",
                      "data": {id: event['source']['userId'], type:"choseType", answer:"餅類"}.to_json
                    }
                ]
            }
          }
        when 'test'
          response = HTTParty.get("#{ENV["API_HOST"]}/api/v1/restaurants/1/dishs")
          reply_message = {
            "type": "text",
            "text": response["data"][0]["data"]["price"]
          }
          reply_message ={
            "type": "template",
            "altText": "this is a buttons template",
            "template": {
                "type": "buttons",
                "title": "Menu",
                "text": "Please select",
                "actions": [{
                  "type": "postback",
                  "label": "#{response['data']}",
                  "data": "action=buy&itemid=123"}]
            }
          }
          # response['data'].each do |item|
          #   message[:template][:actions].push({
          #     "type": "postback",
          #     "label": "#{item['data']['dishname']} #{item['data']['price']}\#{item['data']['unit']}}",
          #     "data": "action=buy&itemid=123"
          #     })
          # end

        else
          reply_message[:text] = '嗨～我是便當小幫手,我還看不懂您指令，你可以輸入help查詢我看得懂的指令喔 ！'
            # reply_message[:text] = event.inspect
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
      when "dishs"
        message = {
          "type": "template",
          "altText": "this is a buttons template",
          "template": {
              "type": "buttons",
              # "thumbnailImageUrl": "https://example.com/bot/images/image.jpg",
              "title": "Menu",
              "text": "Please select",
              "actions": []
          }
        }
        payload[:data].each do |item|
          message[:template][:actions].push({
            "type": "postback",
            "label": item[:data][:dishname],
            "data": "action=buy&itemid=123"
            })
        end
      when "choseType"
      case payload['answer']
      when '水餃類'
      message = {
        "type": "template",
        "altText": "選擇你的餐點數量",
        "template": {
            "type": "carousel",
            "columns": [
                {
                  "title": "豬肉水餃",
                  "text": "周胖子的招牌",
                  "actions": [
                      {
                        "type": "postback",
                        "label": "水餃 x 5",
                        "data": {
                          id: "#{payload['id']}",
                          type: "orderNumber",
                          category: "水餃類",
                          flavor: "豬肉水餃",
                          number: 5
                        }.to_json
                      },
                      {
                        "type": "postback",
                        "label": "水餃 x 10",
                        "data": {
                          id: "#{payload['id']}",
                          type: "orderNumber",
                          category: "水餃類",
                          flavor: "豬肉水餃",
                          number: 10
                        }.to_json
                      },
                      {
                          "type": "postback",
                          "label": "水餃 x 15",
                          "data": {
                            id: "#{payload['id']}",
                            type: "orderNumber",
                            category: "水餃類",
                            flavor: "豬肉水餃",
                            number: 15
                          }.to_json
                      }
                  ]
                },
                {
                  "title": "牛肉水餃",
                  "text": "包牛肉的水餃",
                  "actions": [
                      {
                        "type": "postback",
                        "label": "水餃 x 5",
                        "data": {
                          id: "#{payload['id']}",
                          type: "orderNumber",
                          category: "水餃類",
                          flavor: "牛肉水餃",
                          number: 5
                        }.to_json
                      },
                      {
                        "type": "postback",
                        "label": "水餃 x 10",
                        "data": {
                          id: "#{payload['id']}",
                          type: "orderNumber",
                          category: "水餃類",
                          flavor: "牛肉水餃",
                          number: 10
                        }.to_json
                      },
                      {
                        "type": "postback",
                        "label": "水餃 x 15",
                        "data": {
                          id: "#{payload['id']}",
                          type: "orderNumber",
                          category: "水餃類",
                          flavor: "牛肉水餃",
                          number: 15
                        }.to_json
                      }
                  ]
                }
            ]
        }
      }
      when '餅類'
        message = {
          "type": "template",
          "altText": "選擇你的餐點數量",
          "template": {
              "type": "carousel",
              "columns": [
                  {
                    # "thumbnailImageUrl": "https://example.com/bot/images/item1.jpg",
                    "title": "蔥油餅",
                    "text": "麵粉加蔥做的餅",
                    "actions": [
                        {
                          "type": "postback",
                          "label": "蔥油餅 x 1",
                          "data": {
                            id: "#{payload['id']}",
                            type: "orderNumber",
                            category: "餅類",
                            flavor: "蔥油餅",
                            number: 1
                          }.to_json
                        },
                        {
                          "type": "postback",
                          "label": "蔥油餅 x 2",
                          "data": {
                            id: "#{payload['id']}",
                            type: "orderNumber",
                            category: "餅類",
                            flavor: "蔥油餅",
                            number: 2
                          }.to_json
                        },
                        {
                            "type": "postback",
                            "label": "蔥油餅 x 3",
                            "data": {
                              id: "#{payload['id']}",
                              type: "orderNumber",
                              category: "餅類",
                              flavor: "蔥油餅",
                              number: 3
                            }.to_json
                        }
                    ]
                  },
                  {
                    "title": "牛肉捲餅",
                    "text": "蔥油餅包牛肉",
                    "actions": [
                        {
                          "type": "postback",
                          "label": "牛肉捲餅 x 1",
                          "data": {
                            id: "#{payload['id']}",
                            type: "orderNumber",
                            category: "餅類",
                            flavor: "牛肉捲餅",
                            number: 1
                          }.to_json
                        },
                        {
                          "type": "postback",
                          "label": "牛肉捲餅 x 2",
                          "data": {
                            id: "#{payload['id']}",
                            type: "orderNumber",
                            category: "餅類",
                            flavor: "牛肉捲餅",
                            number: 2
                          }.to_json
                        },
                        {
                          "type": "postback",
                          "label": "牛肉捲餅 x 3",
                          "data": {
                            id: "#{payload['id']}",
                            type: "orderNumber",
                            category: "餅類",
                            flavor: "牛肉捲餅",
                            number: 3
                          }.to_json
                        }
                    ]
                  }
              ]
          }
        }
      end
      client.reply_message(event['replyToken'], message)
      when "orderNumber"
        message = {
          type: 'text',
          text: "#{payload['id']} 點了 #{payload['number']} 個 #{payload['flavor']} \n"
        }
        sum = payload['number'] * restaurant[:restaurant_menu]["#{payload['category']}".to_sym]["#{payload['flavor']}".to_sym]
        message[:text] += "總共是 $#{sum} 元"
        client.reply_message(event['replyToken'], message)
      else
      end
    end
  end

  "OK"
end

end
