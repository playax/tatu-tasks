module Tatu
  class SlackAPI
    def self.fetch_message_text(app_token, channel_id, message_ts)
      params = { token: app_token, channel: channel_id, latest: message_ts, limit: 1, inclusive: true }
      resp = HTTP.get('https://slack.com/api/conversations.history', params: params)
      json = JSON.parse(resp)
      json.dig('messages', 0, 'text')
    end
  end
end
