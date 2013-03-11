require 'redis-namespace'
require 'line_up'

RSpec.configure do |config|

  config.before do
    RawLineUpRedis = Redis.new(db: 14)
    LineUp.redis = Redis::Namespace.new :myapp, redis: RawLineUpRedis
  end

  config.after do
    RawLineUpRedis.flushdb
    LineUp.redis = nil
  end

end
