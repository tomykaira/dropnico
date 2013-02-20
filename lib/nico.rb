require 'lib/nico/agent'
require 'lib/nico/rss'
require 'lib/nico/video'

module Nico
  module_function
  def run_thread(nico_name)
    WorkerThread.new("nico/video/#{nico_name}") do
      download_video(nico_name)
    end
  end

  def download_video(nico_name, agent = nil)
    if nico_name[0, 2] == "nm"
      thread_logger.info "Ignore nm video #{nico_name}"
      return
    end
    Dir.mktmpdir do |dir|
      downloader = Video.new(nico_name, agent)

      retry_at_most(3) do
        downloader.download(dir)
      end

      retry_at_most(3) do
        DropboxUploader.new.upload_directory(dir)
      end
    end
  end

  def download_mylist(list)
    WorkerThread.new("nico/mylist/#{list}") do
      agent = Nico::Agent.new
      files = Nico::RSS.from_list(list, agent).fetch_files

      files.each do |nico_name|
        begin
          download_video(nico_name, agent)
        rescue Exception => e
          thread_logger.fatal("Skipping #{nico_name}, try it again by your self")
        end
      end
    end
  end
end
