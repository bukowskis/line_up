require 'line_up/job'

module LineUp
  extend self

  def push(application, jobclass, *args)
    redis_for(application) do |redis|
      job = Job.new(jobclass, *args)
      redis.sadd 'queues', job.queue_name
      redis.rpush "queue:#{job.queue_name}", job.encode
    end
  end

  def redis=(object)
    @redis = object
  end

  def redis
    return @redis if @redis
    Raidis.redis if defined?(Raidis)
  end

  def redis_for(application, &block)
    redis.namespace "#{application.to_s.underscore}:resque", &block
  end

end
