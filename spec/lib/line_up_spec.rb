require 'spec_helper'

describe LineUp do

  let(:application) { :otherApp }
  let(:job)         { :SendEmail }
  let(:args)        { [123, some: :thing] }
  let(:redis)       { RawLineUpRedis }

  let(:lineup) { LineUp }

  describe '.push' do
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

end
