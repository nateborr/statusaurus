require 'sinatra'

require 'json'
require 'net/http'
require 'uri'

HEROKU_APP_NAME_PREFIX = ENV['HEROKU_APP_NAME_PREFIX'] || ''

post '/deployment' do
  # Get parameter data from Heroku deploy hook.
  app_name = process_app_name(params[:app])
  commit_sha = params[:head_long]

  commit_name = params[:head]

  # Match the SHA to an open GitHub pull request, if any.
  pr_numbers = pull_request_numbers_for_sha(commit_sha)
  if !pr_numbers.first.nil?
    commit_name = "PR #{pr_numbers.first}"
  end

  # Update HipChat room topic with the app name and SHA.
  hipchat_token = 'b1cae1fc129a2e4b3b738d440a17b6'
  hipchat_room_id = '471229'

  message = "#{commit_name} - #{app_name}"

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

  ['OK'].to_json
end

def process_app_name(app_name)
  prefix_match = /#{HEROKU_APP_NAME_PREFIX}(.+)/.match(app_name)
  if prefix_match
    prefix_match[1].upcase
  else
    app_name
  end
end

def get_hipchat_room_topic(room_id, hipchat_token)
  topic = ''

  hc_url = "https://api.hipchat.com/v1/rooms/show?"\
    "room_id=#{room_id}&auth_token=#{hipchat_token}"
  uri = URI.parse hc_url

  response = Net::HTTP.get_response(uri)

  # Parse the response body for a 2xx response.
  if /2\d{2}$/ =~ response.code
    body_hash = JSON.parse(response.body)
    topic = body_hash['room']['topic']
  end

  topic
end

def parse_topic(topic)
  status_hash = {}

  # For each status, match on a complete line that looks like:
  # <commit description> - <app name>
  # ...making some allowances for differences in whitespace.
  status_matcher = /^\s*(.+) - (.+)\s*$/

  statuses = topic.split('::').map(&:strip)
  statuses.each do |status|
    match_data = status_matcher.match(status)
    if match_data
      app_name = match_data[2].strip
      commit_description = match_data[1].strip

      status_hash[process_app_name(app_name)] = commit_description
    end
  end

  status_hash
end

def get_pull_request_data
  # Get open pull requests from GitHub.
  gh_url = "https://api.github.com/repos/hubbubhealth/hubbub-main/pulls"\
  "?access_token=79de2a4541b1198813aa42bf8b51d4aabee81f38"

  uri = URI.parse gh_url

  http = Net::HTTP.new(uri.host, uri.port)
  # http://stackoverflow.com/a/9227933/1489306
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri.request_uri)
  # Need to add User-Agent header:
  # http://developer.github.com/v3/#user-agent-required
  request["User-Agent"] = 'nateborr'
  # http://developer.github.com/v3/media/#beta-v3-and-the-future
  request["Accept"] = "application/vnd.github.v3+json"

  response = http.request(request)

  JSON.parse response.body
end

def pull_request_numbers_for_sha(sha)
  # Get data for open pull requests from GitHub.
  prs = get_pull_request_data

  prs.select {|pr| pr['head']['sha'] == sha}.collect {|pr| pr['number']}
end
