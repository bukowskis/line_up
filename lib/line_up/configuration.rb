require 'logger'

module LineUp
  class Configuration
    attr_accessor :logger, :redis

    def initialize(options={})
      @logger = options[:logger] || default_logger
      @redis  = options[:redis]  || default_redis
    end

    private

    def default_logger
      if defined?(Rails)
        Rails.logger
      else
        Logger.new(STDOUT)
      end
    end

    def default_redis
      return Raidis.redis if defined?(Raidis)
      return Resque.redis if defined?(Resque)
      Redis::Namespace.new nil
    end
  end
end

module LineUp

  # Public: Returns the the Configuration instance.
  #
  def self.config
    @config ||= Configuration.new
  end

  # Public: Yields the Configuration instance.
  #
  def self.configure(&block)
    yield config
  end

  # Public: Reset the Configuration (useful for testing)
  #
  def self.reset!
    @config = nil
  end
end
