require 'worker_logger'

class WorkerThread < Thread
  def initialize(jobname, &block)
    super do
      logger = WorkerLogger.new(jobname)
      LOGGERS << logger
      Thread.current[:logger] = logger

      begin
        block.call
      rescue
        p $!
        thread_logger.fatal($!)
        p $@
        thread_logger.fatal($@)
      end
    end
  end
end

module Kernel
  def thread_logger
    Thread.current[:logger] || GLOBAL_LOGGER
  end

  def retry_at_most(n)
    begin
      yield
    rescue Exception => e
      raise e if n <= 0

      n -= 1
      thread_logger.fatal "$!, Retrying..."
      retry
    end
  end
end
