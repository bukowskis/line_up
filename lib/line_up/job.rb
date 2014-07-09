require 'line_up/string_extensions'
require 'multi_json'
require 'digest/sha1'

module LineUp
  class Job

    attr_reader :klass, :args

    def initialize(klass, *args)
      @klass = klass
      @args = args
    end

    def checksum
      Digest::SHA1.hexdigest(encode)
    end

    def encode
      MultiJson.dump class: klass.to_s, args: args
    end

    def queue_name
      StringExtensions.underscore(klass)
    end

  end
end
