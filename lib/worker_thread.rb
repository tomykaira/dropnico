require 'worker_logger'

class WorkerThread < Thread
  def initialize(jobname, &block)
    super do
      logger = WorkerLogger.new(jobname)
      LOGGERS << logger

      begin
        block.call(logger)
      rescue
        logger.fatal($!)
        p $!
        logger.fatal($@)
        p $@
      end
    end
  end
end
