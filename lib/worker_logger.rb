require 'logger'
require 'stringio'

class WorkerLogger
  attr_reader :work_id

  def new(work_id)
    @work_id = work_id
    @io = StringIO.new
    @logger = Logger.new strio
  end

  def string
    @io.string
  end

  def method_missing(method, *args)
    @logger.__send__(method, *args)
  end
end
