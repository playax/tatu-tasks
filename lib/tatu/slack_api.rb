module Tatu
  class SlackAPI
    class << self
      def fetch_message_text(app_token, channel_id, message_ts)
        params = { token: app_token, channel: channel_id, latest: message_ts, limit: 1, inclusive: true }
        resp = HTTP.get('https://slack.com/api/conversations.history', params: params)
        json = JSON.parse(resp)
        json.dig('messages', 0, 'text')
      end

      def authenticate_slack(body, slack_request_timestamp, slack_signature)
        data = ['v0', slack_request_timestamp, body].join(':')
        hexdigest = OpenSSL::HMAC.hexdigest('SHA256', signing_secret, data)
        expected_signature = "v0=#{hexdigest}"

        slack_signature == expected_signature
      end

      def signing_secret
        ENV['SIGNING_SECRET']
      end
    end
  end
end
