module ForgetMeNot
  module Logging
    attr_accessor :log_activity

    def logger
      return @logger if defined?(@logger)
      @logger = rails_logger || default_logger
    end

    def logger=(logger)
      @logger = logger
    end

    def rails_logger
      defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
    end

    def default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger
    end
  end
end
