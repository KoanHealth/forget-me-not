module ForgetMeNot
  class HashCache
    def fetch(key)
      data[key] ||= yield
    end

    private
    def data
      @data ||= {}
    end
  end
end
