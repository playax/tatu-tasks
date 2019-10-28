require_relative 'lib/tatu'
require 'sinatra'
require 'sinatra/reloader' if development?

also_reload 'lib/tatu'

WORKSPACE = 'playax'

before do
  @body = request.body.read
  halt(401) if !Tatu::SlackAPI.authentic?(request, @body)
end

# For redifining URL on Slack:
# post '/' do
#   JSON.parse(request.body.read)['challenge']
# end

post '/' do
  payload = JSON.parse(@body)
  handle_reaction(payload['event'])
end

post '/list' do
  payload = URI.decode_www_form(@body).to_h
  post_message(payload['channel_id'], payload['user_id'], list_tasks(payload['channel_id']))
end

post '/interaction' do
  payload = JSON.parse(URI.decode_www_form(@body)[0][1])
  action = payload.dig('actions', 0, 'value')
  response_url = payload['response_url']

  case action
  when 'update' then update_message(response_url, list_tasks(payload.dig('container', 'channel_id')))
  when 'delete' then delete_message(response_url)
  end
end

private

def handle_reaction(event)
  item = event['item']
  task = Tatu::Task.new(WORKSPACE, item['channel'], item['ts'])

  case event['reaction']
  when 'warning'
    unless task.persisted?
      task.fetch_text!(ENV['APP_TOKEN'])
      task.persist!
    end
  when 'done'
    task.delete!
  end
end

def list_tasks(channel_id)
  task_list = Tatu::Task.of(WORKSPACE, channel_id).map.with_index(1) do |task, idx|
    "*#{idx}.* #{task.summary} <#{task.url}|:link:>"
  end

  task_list = ['Não há tarefas pendentes neste canal. Eba :tada:'] if task_list.empty?

  message_blocks = [
    build_section(task_list.join("\n")),
    build_actions([build_button(:Fechar, :delete), build_button(:Atualizar, :update)])
  ]
end

def build_section(text)
  build_text_block(:section, text, text_type: :mrkdwn)
end

def build_button(text, value)
  build_text_block(:button, text, value: value)
end

def build_actions(elements)
  { type: :actions, elements: elements }
end

def build_text_block(type, text, opts = {})
  text_type = opts.delete(:text_type) || :plain_text
  { type: type, text: { type: text_type, text: text } }.merge(opts)
end

def post_message(channel_id, user_id, blocks)
  json = { channel: channel_id, user: user_id, blocks: blocks }
  auth_slack_http.post('https://slack.com/api/chat.postEphemeral', json: json)
end

def update_message(response_url, blocks)
  auth_slack_http.post(response_url, json: { blocks: blocks, replace_original: true })
end

def delete_message(response_url)
  auth_slack_http.post(response_url, json: { delete_original: true })
end

def auth_slack_http
  HTTP.auth("Bearer #{ENV['BOT_TOKEN']}")
end
