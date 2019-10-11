require 'google/cloud/firestore'

module Tatu
  class DB
    CONN = Google::Cloud::Firestore.new(project_id: ENV['GCP_PROJECT_ID'])

    class << self
      def tasks(workspace, channel_id)
        tasks_query(workspace, channel_id).get.map(&:data)
      end

      def task_exists?(task)
        task_query(task).get.exists?
      end

      def save_task(task)
        task_query(task).set(task.persistent_attributes)
      end

      def delete_task(task)
        task_query(task).delete
      end

      private

      def tasks_query(workspace, channel_id)
        CONN.col("workspaces/#{workspace}/#{channel_id}")
      end

      def task_query(task)
        tasks_query(task.workspace, task.channel_id).doc(task_doc_id(task))
      end

      def task_doc_id(task)
        "#{task.channel_id}-#{task.message_ts}"
      end
    end
  end
end
