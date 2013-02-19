$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.dirname(__FILE__) + "/lib"

require 'sinatra'
require 'lib/nico_downloader'
require 'lib/youtube'

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
  WorkerThread.new("nico/video/#{video}") do |logger|
    Dir.mktmpdir do |dir|
      downloader = NicoDownloader.new(logger)
      downloader.download(video, dir)

      DropboxUploader.upload_directory(logger, dir)
    end
  end
  "Started"
end

post '/nico/list' do
  list = params['mylist']
  WorkerThread.new do |logger|
    Dir.mktmpdir do |dir|
      downloader = NicoDownloader.new(logger)
      downloader.rss_download("http://www.nicovideo.jp/mylist/#{list}?rss=1.0", dir)

      DropboxUploader.upload_directory(logger, dir)
    end
  end
  "Started"
end

post '/youtube/video' do
  video_id = params['v']
  Youtube.run_thread(video_id)
  "Started #{video_id}"
end

post '/youtube/embedded' do
  ids = Youtube.embedded_ids(params['url'])
  ids.each { |id| Youtube.run_thread(id) }

  "Started #{ids.join(" ")}"
end


get '/log' do
  LOGGERS.map do |l|
    "<h2>#{l.work_id}</h2>" + l.string.gsub("\n", "<br>\n")
  end.join("\n")
end
