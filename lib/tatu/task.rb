module Tatu
  class Task
    attr_reader :workspace, :channel_id, :message_ts, :text

    def self.of(workspace)
      DB.tasks(workspace).map do |data|
        new(workspace, *data.values_at(:channel_id, :message_ts), data[:text])
      end
    end

    def initialize(workspace, channel_id, message_ts, text = nil)
      @workspace = workspace
      @channel_id = channel_id
      @message_ts = message_ts
      @text = text
    end

    def summary
      text&.lines&.first&.strip&.slice(0, 70)
    end

    def url
      "https://#{workspace}.slack.com/archives/#{channel_id}/#{message_ts}"
    end

    def persistent_attributes
      {
        channel_id: channel_id,
        message_ts: message_ts,
        text: text
      }
    end

    def persisted?
      DB.task_exists?(self)
    end

    def persist!
      DB.save_task(self)
    end

    def delete!
      DB.delete_task(self)
    end

    def fetch_text!(app_token)
      @text = Tatu::SlackAPI.fetch_message_text(app_token, channel_id, message_ts)
    end
  end
end
