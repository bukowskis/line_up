require 'spec_helper'

describe LineUp do

  let(:application) { :otherApp }
  let(:job)         { :SendEmail }
  let(:args)        { [123, some: :thing] }
  let(:redis)       { $raw_redis }
  let(:logger)      { mock(:logger) }
  let(:lineup_job)  { LineUp::Job.new job, *args }

  let(:lineup) { LineUp }

  describe '.push' do
    it 'returns true if successful' do
      lineup.push(application, job, *args).should be_true
    end

    it 'registers the queue' do
      lineup.push application, job, *args
      queues = redis.smembers('other_app:resque:queues').should == %w{ send_email }
    end

    it 'enqueues the job' do
      lineup.push application, job, *args
      jobs = redis.lrange('other_app:resque:queue:send_email', 0, -1)
      jobs.size.should == 1
      MultiJson.load(jobs.first).should == { 'class' => 'SendEmail', 'args' => [123, 'some' => 'thing'] }
    end

    context 'with a Logger' do
      before do
        lineup.config.logger = logger
      end

      it 'logs the enqueueing and returns true' do
        logger.should_receive(:debug) do |string|
          string.should include('LINEUP ENQUEUED')
          string.should include('line_up_spec.rb')
          string.should include(':otherApp')
          string.should include(':SendEmail')
          string.should include('[123, {:some=>:thing}]')
        end
        lineup.push(application, job, *args).should be_true
      end
    end

    context 'when the key for the Queue Set is occupied by the wrong data format' do
      before do
        redis.set 'other_app:resque:queues', :anything_but_a_list
      end

      it 'catches the error and returns false' do
        Trouble.should_receive(:notify) do |exception, metadata|
          exception.should be_instance_of Redis::CommandError
          metadata[:code].should == :enqueue_failed
          metadata[:application].should == ':otherApp'
          metadata[:job].should == ':SendEmail'
          metadata[:args].should == '[123, {:some=>:thing}]'
          metadata[:caller].should include('line_up_spec.rb')
        end
        lineup.push(application, job, *args).should be_false
      end
    end

    context 'when the key for the List Job Queue is occupied by the wrong data format' do
      before do
        redis.set 'other_app:resque:queue:send_email', :anything_but_a_list
      end

      it 'catches the error and returns false' do
        Trouble.should_receive(:notify) do |exception, metadata|
          exception.should be_instance_of Redis::CommandError
          metadata[:code].should == :enqueue_failed
          metadata[:application].should == ':otherApp'
          metadata[:job].should == ':SendEmail'
          metadata[:args].should == '[123, {:some=>:thing}]'
          metadata[:caller].should include('line_up_spec.rb')
        end
        lineup.push(application, job, *args).should be_false
      end
    end
  end

  describe ".queue_length" do

    it "returns the length of the given queue in the given application" do
      lineup.push(application, job, 1)
      lineup.push(application, job, 2)
      lineup.queue_length(application, job).should == 2
    end

    context 'when the key for the List Job Queue is occupied by the wrong data format' do
      before do
        redis.set 'other_app:resque:queue:send_email', :anything_but_a_list
      end

      it 'logs the error' do
        Trouble.should_receive(:notify) do |exception, metadata|
          exception.should be_instance_of Redis::CommandError
          metadata[:code].should == :getting_queue_length_failed
          metadata[:application].should == ':otherApp'
          metadata[:job].should == ':SendEmail'
          metadata[:caller].should include('line_up_spec.rb')
        end
        lineup.queue_length(application, job)
      end

      it "returns false" do
        lineup.queue_length(application, job).should be_false
      end
    end
  end

  describe ".ensure" do

    it "pushes the job if the queue is empty" do
      lineup.should_receive(:push).with(application, job, *args)
      lineup.ensure application, job, *args
    end

    it "does not push the job if the queue already has a job with the same name" do
      lineup.push application, job, *args
      lineup.should_not_receive(:push)
      lineup.ensure application, job, *args
    end
  end

  describe ".push_throttled" do

    it "pushes same consecutive job just once" do
      lineup.should_receive(:push).once
      lineup.push_throttled application, job, *args
      lineup.push_throttled application, job, *args
    end

    it "pushes again when previous identical job has expired" do
      lineup.should_receive(:push).twice

      lineup.push_throttled application, job, *args
      redis.del "other_app:resque:throttled:#{lineup_job.checksum}"
      lineup.push_throttled application, job, *args
    end

    it "stores throttle with configured ttl" do
      lineup.push_throttled application, job, *args
      ttl = redis.ttl "other_app:resque:throttled:#{lineup_job.checksum}"
      ttl.should == lineup.config.recency_ttl
    end

  end

end
