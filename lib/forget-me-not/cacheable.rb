module ForgetMeNot
# Allows the cross-system caching of lengthy function calls
  module Cacheable
    class << self
      def included(base)
        base.extend(ClassMethods)
        Cacheable.cachers << base
      end
    end

    module ClassMethods
      def cache_results(*methods)
        options = methods.last.is_a?(Hash) ? methods.pop : {}
        methods.each { |m| cache_method(m, options) }
      end

      def cache_warm(*args)
        # Classes can call the methods necessary to warm the cache
      end

      private
      def cache_method(method_name, options)
        method = instance_method(method_name)
        visibility = method_visibility(method_name)
        define_cache_method(method, options)
        send(visibility, method_name)
      end

      def define_cache_method(method, options)
        method_name = method.name.to_sym
        key_prefix = "/cached_method_result/#{self.name}"
        instance_key = get_instance_key_proc(options[:include]) if options.has_key?(:include)

        undef_method(method_name)
        define_method(method_name) do |*args|
          cache_key = [
            key_prefix,
            (instance_key && instance_key.call(self)),
            method_name,
            args.hash
          ].compact.join '/'

          puts "key: #{cache_key}" if (defined?(Rails) && Rails.env.test?)

          Cacheable.cache_fetch(cache_key) do
            method.bind(self).call(*args)
          end
        end
      end

      def get_instance_key_proc(instance_key_methods)
        instance_keys = Array.new(instance_key_methods).flatten
        Proc.new do |instance|
          instance_keys.map { |key| instance.send(key) }.hash
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

    def self.cache_fetch(key, &block)
      cache.fetch(key, cache_options, &block)
    end

    def self.cache
      @cache ||= default_cache
    end

    def self.cache=(value)
      @cache = value
    end

    def self.cache_options
      @cache_options ||= {expires_in: 12 * 60 * 60}
      @cache_options.merge(Cacheable.cache_options_threaded)
    end

    def self.cache_options_threaded
      Thread.current['cacheable-cache-options'] || {}
    end

    def self.cache_options_threaded=(options)
      Thread.current['cacheable-cache-options'] = options
    end

    def self.cachers
      @cachers ||= Set.new
    end

    def self.cachers_and_descendants
      all_cachers = Set.new
      Cacheable.cachers.each do |c|
        all_cachers << c
        all_cachers += c.descendants if c.is_a? Class
      end
      all_cachers
    end

    def self.warm(*args)
      begin
        Cacheable.cache_options_threaded = {force: true}
        Cacheable.cachers_and_descendants.each { |cacher| cacher.cache_warm(*args) }
      ensure
        Cacheable.cache_options_threaded = nil
      end
    end

    private
    def self.default_cache
      rails_cache ||
      active_support_cache ||
      raise(
      <<-ERR_TEXT
        When using Cacheable in a project that does not have a Rails or ActiveSupport Cache,
        you must explicitly set the cache to an object shaped like ActiveSupport::Cache::Store
        ERR_TEXT
        )
    end

    def self.rails_cache
      defined?(Rails) && Rails.cache
    end

    def self.active_support_cache
      defined?(ActiveSupport) &&
        defined?(ActiveSupport::Cache) &&
        defined?(ActiveSupport::Cache::MemoryStore) &&
        ActiveSupport::Cache::MemoryStore.new
    end

  end
end
