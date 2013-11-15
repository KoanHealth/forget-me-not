module ForgetMeNot
# Allows the memoization of method calls
  module Memoizable
    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def memoize(*methods)
        options = methods.last.is_a?(Hash) ? methods.pop : {}
        methods.each { |m| memoize_method(m, options) }
      end

      private
      def memoize_method(method_name, options)
        method = instance_method(method_name)
        visibility = method_visibility(method_name)
        define_memoized_method(method, options)
        send(visibility, method_name)
      end

      def define_memoized_method(method, options)
        method_name = method.name.to_sym
        key_prefix = "/memoized_method_result/#{self.name}"

        undef_method(method_name)
        define_method(method_name) do |*args|
          memoize_key = [
            key_prefix,
            method_name,
            args.hash
          ].compact.join '/'

          puts "key: #{memoize_key}" if (defined?(Rails) && Rails.env.test?)

          fetch_from_storage(memoize_key) do
            method.bind(self).call(*args)
          end
        end
      end

      def method_visibility(method)
        if private_method_defined?(method)
          :private
        elsif protected_method_defined?(method)
          :protected
        else
          :public
        end
      end
    end

    def fetch_from_storage(key, &block)
      storage.fetch(key, &block)
    end

    def storage
      @storage ||= Memoizable.storage_builder.call
    end

    class << self
      def storage_builder
        @storage_builder ||= Proc.new {HashCache.new}
      end

      def storage_builder=(builder)
        @storage_builder = builder
      end
    end

  end
end
