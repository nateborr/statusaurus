require 'sinatra'

require 'net/http'
require 'uri'

post 'deployment' do
  # Get parameter data from Heroku deploy hook.
  app_name = params[:app]
  commit_sha = params[:head_long]

  # Update HipChat room topic with the app name and SHA.
  hipchat_token = 'b1cae1fc129a2e4b3b738d440a17b6'
  hipchat_room_id = '471229'

  message = "#{commit_sha} is in #{app_name}"

  url = "https://api.hipchat.com/v1/rooms/topic?auth_token=#{hipchat_token}"
  uri = URI.parse url
  
  response = Net::HTTP.post_form(
    uri,
    {
      room_id: hipchat_room_id,
      topic: message,
      from: 'Statusaurus'
    }
  )

  #Net::HTTP.get(URI.parse(url))
end
