module LineUp
  class StringExtensions

    # See https://github.com/rails/rails/blob/master/activesupport/lib/active_support/inflector/methods.rb#L90
    def self.underscore(word)
      unless word.nil?
        word = word.to_s
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
      end
      word
    end

  end
end
