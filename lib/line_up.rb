require 'trouble'

require 'line_up/configuration'
require 'line_up/job'

module LineUp
  RedisNotConfiguredError = Class.new(RuntimeError)

  def self.push(application, jobclass, *args)
    redis_for application do |redis|
      job = Job.new jobclass, *args
      redis.sadd 'queues', job.queue_name
      redis.rpush "queue:#{job.queue_name}", job.encode
    end
    log caller, application, jobclass, *args
    true
  rescue Exception => exception
    Trouble.notify exception, caller: caller[1], message: "LineUp could not enqueue a Job", code: :enqueue_failed, redis: config.redis.inspect, application: application.inspect, job: jobclass.inspect, args: args.inspect
    false
  end

  def self.ensure(application, jobclass, *args)
    if queue_length(application, jobclass) == 0
      push(application, jobclass, *args)
    end
  end

  def self.push_throttled(application, jobclass, *args)
    job = Job.new jobclass, *args
    unless recent? application, job
      push(application, jobclass, *args)
      recent! application, job
    end
  end

  def self.queue_length(application, jobclass)
    redis_for application do |r|
      job = Job.new jobclass
      return r.llen "queue:#{job.queue_name}"
    end
  rescue Exception => e
    Trouble.notify e, caller: caller[1], message: "LineUp could not get the queue length", code: :getting_queue_length_failed, redis: config.redis.inspect, application: application.inspect, job: jobclass.inspect
    false
  end

  private

  def self.recent?(application, job)
    redis_for application do |r|
      return true if r.exists "throttled:#{job.checksum}"
    end
    false
  end

  def self.recent!(application, job)
    redis_for application do |r|
      r.setex "throttled:#{job.checksum}", config.recency_ttl, "true"
    end
  end

  def self.redis_for(application, &block)
    config.redis.namespace [StringExtensions.underscore(application), :resque].compact.join(':'), &block
  end

  def self.log(caller, application, jobclass, *args)
    return unless config.logger
    config.logger.debug "LINEUP ENQUEUED JOB #{jobclass.inspect} for #{application.inspect} at #{caller.first} with arguments #{args.inspect}"
  end

end
