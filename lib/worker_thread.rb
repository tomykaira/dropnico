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
end
