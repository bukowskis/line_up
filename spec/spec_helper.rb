require 'redis-namespace'
require 'line_up'

def ensure_class_or_module(full_name, class_or_module)
  full_name.to_s.split(/::/).inject(Object) do |context, name|
    begin
      context.const_get(name)
    rescue NameError
      if class_or_module == :class
        context.const_set(name, Class.new)
      else
        context.const_set(name, Module.new)
      end
    end
  end
end

def ensure_module(name)
  ensure_class_or_module(name, :module)
end

def ensure_class(name)
  ensure_class_or_module(name, :class)
end

ensure_module :Trouble

RSpec.configure do |config|

  config.before do
    Trouble.stub!(:notify)
    $raw_redis = Redis.new(db: 14)
    LineUp.redis = Redis::Namespace.new :myapp, redis: $raw_redis
  end

  config.after do
    $raw_redis.flushdb
    LineUp.redis = nil
  end

end
