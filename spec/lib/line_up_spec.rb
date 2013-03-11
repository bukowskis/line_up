require 'spec_helper'

describe LineUp do

  let(:application) { :otherApp }
  let(:job)         { :SendEmail }
  let(:args)        { [123, some: :thing] }
  let(:redis)       { $raw_redis }

  let(:lineup) { LineUp }

  describe '.push' do
    context 'under normal conditions' do
      before do
        lineup.push application, job, *args
      end

      it 'registers the queue' do
        queues = redis.smembers('other_app:resque:queues').should == %w{ send_email }
      end

      it 'enqueues the job' do
        jobs = redis.lrange('other_app:resque:queue:send_email', 0, -1)
        jobs.size.should == 1
        JSON.load(jobs.first).should == { 'class' => 'SendEmail', 'args' => [123, 'some' => 'thing'] }
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
        end
        lineup.push(application, job, *args).should be_false
      end
    end

    context 'when Redis has never been configured' do
      before do
        LineUp.redis = nil
      end

      it 'catches the error and returns false' do
        Trouble.should_receive(:notify) do |exception, metadata|
          exception.should be_instance_of Redis::CannotConnectError
          metadata[:code].should == :enqueue_failed
          metadata[:application].should == ':otherApp'
          metadata[:job].should == ':SendEmail'
          metadata[:args].should == '[123, {:some=>:thing}]'
        end
        lineup.push(application, job, *args).should be_false
      end
    end

    context 'when Redis is unavailable' do
      before do
        LineUp.redis = Redis.new(host: '192.0.2.1', timeout: 0.1)  # RFC 5737
      end

      it 'catches the error and returns false' do
        Trouble.should_receive(:notify) do |exception, metadata|
          exception.should be_instance_of Redis::CannotConnectError
          metadata[:code].should == :enqueue_failed
          metadata[:application].should == ':otherApp'
          metadata[:job].should == ':SendEmail'
          metadata[:args].should == '[123, {:some=>:thing}]'
        end
        lineup.push(application, job, *args).should be_false
      end
    end

  end
end
