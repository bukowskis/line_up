require 'line_up/string_extensions'
require 'multi_json'

module LineUp
  class Job

    attr_reader :klass, :args

    def initialize(klass, *args)
      @klass = klass
      @args = args
    end

    def encode
      MultiJson.dump class: klass.to_s, args: args
    end

    def queue_name
      StringExtensions.underscore(klass)
    end

  end
end
