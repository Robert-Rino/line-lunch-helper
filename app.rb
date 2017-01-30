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
        # message = {
        #   type: 'text',
        #   text: event.message['text']
        # }
        message = {
          type: 'template',
          altText: 'this is a button template',
          template: {
            type: 'buttons',
            thumbnailImageUrl:
          'https://cdn2.iconfinder.com/data/icons/despicable-me-2-minions/128/Curious-Minion-Icon.png',
            title: 'menu',
            text: 'please select',
            actions: [
              {
                type: 'postback',
                label: 'Bob',
                data: 'press Bob',
              },
              {
                type: 'postback',
                label: 'Kevin',
                data: 'press Kevin',
              }
            ]
          }
        }
        client.reply_message(event['replyToken'], message)
      # when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
      #   response = client.get_message_content(event.message['id'])
      #   tf = Tempfile.open("content")
      #   tf.write(response.body)
      end
    when Line::Bot::Event::Postback

      payload = JSON.parse(event['postback']['data'])
      message = {
        type: 'text',
        text: "謝謝您的回應！ :D"
      }
      client.reply_message(event['replyToken'], message)
      message_payload_string = redis.get payload['id']

    end
  end

  "OK"
end

end
