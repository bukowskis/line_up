require 'line_up/job'

module LineUp
  extend self

  RedisNotConfiguredError = Class.new(RuntimeError)

  def push(application, jobclass, *args)
    unless redis
      Trouble.notify RedisNotConfiguredError.new, message: "LineUp cannot enqueue a Job", code: :enqueue_failed, redis: redis.inspect, application: application.inspect, job: jobclass.inspect, args: args.inspect
      return false
    end
    redis_for(application) do |redis|
      job = Job.new(jobclass, *args)
      redis.sadd 'queues', job.queue_name
      redis.rpush "queue:#{job.queue_name}", job.encode
    end
    true
  rescue Exception => exception
    raise exception unless defined?(Trouble)
    Trouble.notify exception, message: "LineUp cannot enqueue a Job", code: :enqueue_failed, application: application.inspect, job: jobclass.inspect, args: args.inspect
    false
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
