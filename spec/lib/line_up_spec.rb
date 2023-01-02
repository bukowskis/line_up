require 'spec_helper'

describe LineUp do

  let(:application) { :otherApp }
  let(:job)         { :SendEmail }
  let(:args)        { [123, some: :thing] }
  let(:redis)       { $raw_redis }
  let(:logger)      { double(:logger) }
  let(:lineup_job)  { LineUp::Job.new job, *args }

  let(:lineup) { LineUp }

  describe '.push' do
    it 'registers the queue' do
      lineup.push application, job, *args
      expect(redis.smembers('other_app:resque:queues')).to eq(%w{ send_email })
    end

    it 'enqueues the job' do
      lineup.push application, job, *args
      jobs = redis.lrange('other_app:resque:queue:send_email', 0, -1)
      expect(jobs.size).to eq(1)
      expect(MultiJson.load(jobs.first)).to eq({ 'class' => 'SendEmail', 'args' => [123, 'some' => 'thing'] })
    end

    context 'with a Logger' do
      before do
        lineup.config.logger = logger
      end

      it 'logs the enqueueing and returns true' do
        expect(logger).to receive(:debug) do |string|
          expect(string).to include('LINEUP ENQUEUED')
          expect(string).to include('line_up_spec.rb')
          expect(string).to include(':otherApp')
          expect(string).to include(':SendEmail')
          expect(string).to include('[123, {:some=>:thing}]')
        end
        lineup.push application, job, *args
      end
    end
  end

  describe ".queue_length" do
    it "returns the length of the given queue in the given application" do
      lineup.push(application, job, 1)
      lineup.push(application, job, 2)
      expect(lineup.queue_length(application, job)).to eq(2)
    end
  end

  describe ".ensure" do
    it "pushes the job if the queue is empty" do
      expect(lineup).to receive(:push).with(application, job, *args)
      lineup.ensure application, job, *args
    end

    it "does not push the job if the queue already has a job with the same name" do
      lineup.push application, job, *args
      expect(lineup).not_to receive(:push)
      lineup.ensure application, job, *args
    end
  end
end
