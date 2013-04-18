[![Build Status](https://travis-ci.org/bukowskis/line_up.png)](https://travis-ci.org/bukowskis/line_up)

# LineUp

With LineUp you can enqueue Resque jobs in arbitrary Redis namespaces.

[Resque](https://github.com/defunkt/resque) uses a [Set](http://redis.io/commands#set) and a [List](http://redis.io/commands#list) to keep track of all Queues and their Jobs.

* The Set is usually located at `resque:queues` and contains a list of (lower-cased, underscored) Strings, each representing a queue name
* Each queue is a List located at `resque:queue:my_job` (with `my_job` as queue name for `MyJob`-jobs in this example)
* Each job inside of a queue is a JSON or Marshal'ed Hash with the keys `class` and `args`, for example `{ class: 'MyJob', args: [123, some: thing] }.to_json`

Depending on how you configure the Redis backend for Resque, you will end up in a different namespace:

* If you use `Resque.redis = Redis::Namespace.new(:bob, ...)`, Resque [detects](https://github.com/defunkt/resque/blob/master/lib/resque.rb#L55) that you passed in an `Redis::Namespace` object and will __not__ add any additional namespace. So the queue Set in this example will be located at `bob:queues`
* Any other `Redis.new`-compatible object will get the `resque`-namespace added. So `Resque.redis = Redis.new(...)` will cause the queue Set to be located at `resque:queues`

If you use multiple applications, you should make sure that each of them has its own namespace. You would normally achieve that with `Resque.redis = Redis::Namespace.new('myapp:resque', ...)` so that the queue Set would be located at `myapp:resque:queues`.

So far so good, __but__ there is no way to enqueue a Job for an application from inside another namespace, say `otherapp:resque:queues`, without maintaining an additional connection to Redis in the other app's namespace. So far, the only solution has been to share the `resque:queues` namespace between all applications and have separate queue-names, such as `myapp-myjob` and `otherapp-myjob`, but that is not really separating namespaces.

That's where LineUp comes in, it doesn't even need Resque. It goes right into Redis (scary huh?), just as Resque does [internally](https://github.com/defunkt/resque/blob/master/lib/resque/queue.rb).

# Examples

### Setup

If you use the `Raidis` gem, you _do not need_ any setup. Otherwise, a manual setup would look like this:

```ruby
redis = Redis::Namespace.new 'myapp:resque', redis: Redis.new(...)

Resque.redis = redis
LineUp.redis = redis
````

### Usage

With the setup above, Resque lies in the `myapp:resque`-namespace. So you can enqeueue jobs to the very same application by using `Resque.enqueue(...)`.

This is how you can enqueue a job for another applications:

```ruby
if LineUp.push :otherApp, :SomeJob, 12345, some: thing
# Yey, everything went well
else
# The "Trouble"-gem, has been notified and I can process the failure if I like
end
```

This will enqueue to `other_app:resque:some_job` with arguments `[12345, { 'some' => 'thing' }]` and make sure that the `other_app:resque:queues` Set references the queue List.

# Gotchas

* `Resque.redis` MUST respond to a method called `#namespace` which takes a block and yields a new namespace. See [this commit](https://github.com/defunkt/redis-namespace/pull/50). Currently LineUp [requires a non-rubygems fork](https://github.com/bukowskis/line_up/blob/master/Gemfile) of `Redis::Namespace` in order to be able to use this cutting-edge method.
* Currently the jobs are encoded using `MultiJson` only, not `Marshal`, feel free to commit a patch if you need the latter
* You cannot share the `resque` root namespace. LineUp defaults to the `application:resque` namespace (because that's the only scenario I can think of that would make you want to use LineUp in the first place :)
