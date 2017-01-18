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


  # get '/api/v1/configurations/?' do
  #   content_type 'application/json'
  #   id_list = Configuration.all
  #
  #   { configuration_id: id_list }.to_json
  # end
  #
  # get '/api/v1/configurations/:id/document' do
  #   content_type 'text/plain'
  #
  #   begin
  #     Base64.strict_decode64 Configuration.find(params[:id]).document
  #   rescue => e
  #     status 404
  #     e.inspect
  #   end
  # end
  #
  # get '/api/v1/configurations/:id.json' do
  #   content_type 'application/json'
  #
  #   begin
  #     { configuration: Configuration.find(params[:id]) }.to_json
  #   rescue => e
  #     status 404
  #     logger.info "FAILED to GET configuration: #{e.inspect}"
  #   end
  # end
  #
  # post '/api/v1/configurations/?' do
  #   content_type 'application/json'
  #
  #   begin
  #     new_data = JSON.parse(request.body.read)
  #     new_config = Configuration.new(new_data)
  #     if new_config.save
  #       logger.info "NEW CONFIGURATION STORED: #{new_config.id}"
  #     else
  #       halt 400, "Could not store config: #{new_config}"
  #     end
  #
  #     redirect '/api/v1/configurations/' + new_config.id + '.json'
  #   rescue => e
  #     status 400
  #     logger.info "FAILED to create new config: #{e.inspect}"
  #   end
  # end
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
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        message = {
          type: 'text',
          text: event.message['text']
        }
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end

end
