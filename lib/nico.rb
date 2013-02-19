require 'lib/nico/agent'
require 'lib/nico/rss'
require 'lib/nico/video'

module Nico
  module_function
  def run_thread(nico_name)
    WorkerThread.new("nico/video/#{nico_name}") do
      if nico_name[0, 2] == "nm"
        thread_logger.info "Ignore nm video #{nico_name}"
        next
      end
      Dir.mktmpdir do |dir|
        downloader = Video.new(nico_name)

        retry_at_most(3) do
          downloader.download(dir)
        end

        retry_at_most(3) do
          DropboxUploader.new.upload_directory(dir)
        end
      end
    end
  end

  def download_mylist(list)
    WorkerThread.new("nico/mylist/#{list}") do
      Dir.mktmpdir do |dir|
        files = Nico::RSS.from_list(list).fetch_files

        files.each do |nico_name|
          run_thread(nico_name)
        end
      end
    end
  end
end
