require_relative 'spec_helper'

require_relative '../web'

RSpec.describe Sinatra::Application do
  describe 'authentication' do
    context 'when no authentication is given' do
      it 'returns 401' do
        post '/'

        expect(last_response.status).to eq 401
      end
    end

    context 'when authentication is given' do
      it 'does not return 401' do
        ENV['SIGNING_SECRET'] = 'my-key'

        header 'X_SLACK_REQUEST_TIMESTAMP', '1569611411'
        header 'X_SLACK_SIGNATURE', 'v0=8afaf4b136bb3bd57cb3541fd49ca30182e1f9a55525fa8492f9ec207a60709e'
        header 'Content-Type', 'application/json'

        json = { foo: :bar }.to_json

        post '/', json

        expect(last_response.status).not_to eq 401
      end
    end
  end

  describe 'task management' do
    before { expect(Tatu::SlackAPI).to receive(:authentic?).and_return(true) }

    describe 'creation and deletion' do
      let(:task) { instance_double(Tatu::Task) }
      let(:json) do
        {
          'event' => {
            'item' => {
              'channel' => 'channel_id',
              'ts' => 'ts'
            }
          }
        }
      end

      before do
        expect(Tatu::Task).to receive(:new).with(any_args, 'channel_id', 'ts').and_return(task)
      end

      describe 'creation' do
        before do
          json['event'].merge!('reaction' => 'warning')
        end

        context 'when requested task is persisted' do
          it 'does nothing' do
            expect(task).to receive(:persisted?).and_return(true)
            expect(task).not_to receive(:persist!)

            post '/', json.to_json
          end
        end

        context 'when requested task is not persisted' do
          it 'persists task' do
            expect(task).to receive(:persisted?).and_return(false)
            expect(task).to receive(:fetch_text!)
            expect(task).to receive(:persist!)

            post '/', json.to_json
          end
        end
      end

      describe 'completing' do
        before do
          json['event'].merge!('reaction' => 'done')
        end

        it 'deletes task' do
          expect(task).to receive(:delete!)

          post '/', json.to_json
        end
      end
    end

    ######  Mock Tatu::DB or use VCR
    #
    # describe 'listing' do
    #   it 'lists tasks' do
    #     body = { 'channel_id' => 'channel_id', 'user_id' => 'user_id' }
    #     post '/list', body
    #   end
    # end
  end

end

