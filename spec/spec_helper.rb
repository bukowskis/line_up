require 'redis-namespace'
require 'line_up'

RSpec.configure do |config|

  config.before do
    $raw_redis = Redis.new(db: 14)
    LineUp.config.redis = Redis::Namespace.new :myapp, redis: $raw_redis
    LineUp.config.logger = nil
  end

  config.after do
    $raw_redis.flushdb
    LineUp.reset!
  end

end
