module Tatu
  class DB
    CONN = Google::Cloud::Firestore.new(project_id: ENV['GCP_PROJECT_ID'])

    class << self
      def tasks(worskpace)
        tasks_query(workspace).get.map(&:data)
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

      def tasks_query(workspace)
        CONN.col("workspaces/#{workspace}/tasks")
      end

      def task_query(task)
        tasks_query(task.workspace).doc(task_doc_id(task))
      end

      def task_doc_id(task)
        "#{task.channel_id}-#{task.message_ts}"
      end
    end
  end
end
