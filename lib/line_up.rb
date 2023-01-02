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
  end

  def self.ensure(application, jobclass, *args)
    if queue_length(application, jobclass) == 0
      push(application, jobclass, *args)
    end
  end

  def self.queue_length(application, jobclass)
    redis_for application do |r|
      job = Job.new jobclass
      return r.llen "queue:#{job.queue_name}"
    end
  end

  private

  def self.redis_for(application, &block)
    config.redis.namespace [StringExtensions.underscore(application), :resque].compact.join(':'), &block
  end

  def self.log(caller, application, jobclass, *args)
    return unless config.logger
    config.logger.debug "LINEUP ENQUEUED JOB #{jobclass.inspect} for #{application.inspect} at #{caller.first} with arguments #{args.inspect}"
  end
end
