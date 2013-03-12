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

  private

  def self.redis_for(application, &block)
    config.redis.namespace "#{StringExtensions.underscore(application)}:resque", &block
  end

  def self.log(caller, application, jobclass, *args)
    return unless config.logger
    rows = ['LINEUP ENQUEUED A JOB']
    rows << "   | Location:    #{caller.first}"
    rows << "   | Application: #{application.inspect}"
    rows << "   | Job Class:   #{jobclass.inspect}"
    rows << "   \\ Arguments:  #{args.inspect}\n"
    config.logger.debug rows.join("\n")
  end

end
