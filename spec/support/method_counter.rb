module MethodCounter
  extend ActiveSupport::Concern
  module ClassMethods
    def clear_calls
      calls.clear
    end

    def calls
      @@calls ||= Hash.new(0)
    end

    def count(method_name)
      calls[method_name]
    end

    def record_call(method_name)
      calls[method_name] += 1
    end
  end

  def record_call(method_name)
    self.class.record_call(method_name)
  end
end
