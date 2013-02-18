$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.dirname(__FILE__) + "/lib"

require 'sinatra'
require 'nico_downloader'
require 'youtube_downloader'
require 'worker_logger'
require 'dropbox_uploader'

LOGGERS = []

get '/'do
  <<HTML
<h1>Download a niconico file</h1>
<form action="/nico/video" method="POST">
<input type="text" name="sm" id="sm" />
<input type="submit" name="submit" value="Download">
</form>
<h1>Download a niconico list</h1>
<form action="/nico/list" method="POST">
<input type="text" name="mylist" id="mylist" />
<input type="submit" name="submit" value="Download">
</form>
<h1>Download a youtube file</h1>
<form action="/youtube/video" method="POST">
<input type="text" name="v" id="v" />
<input type="submit" name="submit" value="Download">
</form>
<h1>Download embedded youtube files in HTML</h1>
<form action="/youtube/embedded" method="POST">
<input type="text" name="url" id="url" />
<input type="submit" name="submit" value="Download">
</form>
HTML
end

post '/nico/video' do
  video = params['sm']
  Thread.new do
    logger = WorkerLogger.new("nico/video/#{video}")
    LOGGERS << logger
    begin
      Dir.mktmpdir do |dir|
        downloader = NicoDownloader.new(logger)
        downloader.download(video, dir)

        uploader = DropboxUploader.new(logger)
        uploader.upload_directory(dir)
      end
    rescue
      logger.fatal($!)
      p $!
      logger.fatal($@)
      p $@
    end
  end
  "Started"
end

post '/nico/list' do
  list = params['mylist']
  Thread.new do
    logger = WorkerLogger.new("nico/mylist/#{list}")
    LOGGERS << logger
    begin
      Dir.mktmpdir do |dir|
        downloader = NicoDownloader.new(logger)
        downloader.rss_download("http://www.nicovideo.jp/mylist/#{list}?rss=1.0", dir)

        uploader = DropboxUploader.new(logger)
        uploader.upload_directory(dir)
      end
    rescue
      logger.fatal($!)
      p $!
      logger.fatal($@)
      p $@
    end
  end
  "Started"
end

post '/youtube/video' do
  video_id = params['v']
  run_youtube_downloader(video_id)
  "Started #{video_id}"
end

post '/youtube/embedded' do
  ids = extract_embedded_video_ids(params['url'])
  ids.map { |id| run_youtube_downloader(id) }

  "Started #{ids.join(" ")}"
end

def extract_embedded_video_ids(url)
  agent = Mechanize.new
  agent.get(url)
  agent.page.search('embed').map do |embed|
    if embed.attributes['type'].value == "application/x-shockwave-flash"
      embed.attributes['src'].value =~ /www\.youtube\.com\/v\/([^&?]*)/
      $1
    end
  end.compact
end

def run_youtube_downloader(video_id)
  Thread.new do
    logger = WorkerLogger.new("youtube/video/#{video_id}")
    LOGGERS << logger
    begin
      Dir.mktmpdir do |dir|
        downloader = YoutubeDownloader.new(logger, video_id)
        downloader.download(dir)

        uploader = DropboxUploader.new(logger)
        uploader.upload_directory(dir)
      end
    rescue
      logger.fatal($!)
      p $!
      logger.fatal($@)
      p $@
    end
  end
end

get '/log' do
  LOGGERS.map do |l|
    "<h2>#{l.work_id}</h2>" + l.string.gsub("\n", "<br>\n")
  end.join("\n")
end
