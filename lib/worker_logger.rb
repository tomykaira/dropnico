require 'logger'
require 'stringio'

class WorkerLogger
  attr_reader :work_id

  def initialize(work_id)
    @work_id = work_id
    @io = StringIO.new
    @logger = Logger.new @io
  end

  def string
    @io.string
  end

  def to_s
    "WorkerLogger #{@work_id}"
  end

  def method_missing(method, *args)
    @logger.__send__(method, *args)
  end
end
