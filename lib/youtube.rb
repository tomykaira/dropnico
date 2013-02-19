require 'lib/worker_thread'
require 'lib/dropbox_uploader'
require 'lib/youtube/video'
require 'lib/youtube/url'

module Youtube
  module_function
  def embedded_ids(url)
    agent = Mechanize.new
    agent.get(url)
    agent.page.search('embed').map do |embed|
      if embed.attributes['type'].value == "application/x-shockwave-flash"
        embed.attributes['src'].value =~ /www\.youtube\.com\/v\/([^&?]*)/
        $1
      end
    end.compact
  end

  def run_thread(video_id)
    WorkerThread.new("youtube/video/#{video_id}") do |logger|
      Dir.mktmpdir do |dir|
        downloader = Video.new(logger, video_id)
        downloader.download(dir)

        DropboxUploader.upload_directory(logger, dir)
      end
    end
  end
end
