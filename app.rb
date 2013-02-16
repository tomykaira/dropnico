$LOAD_PATH << 'lib'

require 'sinatra'
require 'nico_downloader'
require 'worker_logger'

LOGGERS = []

get '/'do
  <<HTML
<a href="/video">Download a file</a>
<a href="/list">Download a list</a>
HTML
end

get '/video' do
  <<HTML
<h1>Download a file</h1>
<form action="/video" method="POST">
<input type="text" name="sm" id="sm" />
<input type="submit" name="submit" value="Download">
</form>
HTML
end

post '/video' do
  video = params['sm']
  Thread.new do
    logger = WorkerLogger.new("video/#{video}")
    LOGGERS << logger
    downloader = NicoDownloader.new(logger)
    downloader.download(video)
  end
end

get '/list' do
  <<HTML
<h1>Download a list</h1>
<form action="/list" method="POST">
<input type="text" name="mylist" id="mylist" />
<input type="submit" name="submit" value="Download">
</form>
HTML
end

post '/list' do
  list = params['mylist']
  Thread.new do
    logger = WorkerLogger.new("mylist/#{list}")
    LOGGERS << logger
    downloader = NicoDownloader.new(logger)
    downloader.rss_download("http://www.nicovideo.jp/mylist/#{list}?rss=1.0")
  end
end

get '/log' do
  LOGGERS.map do |l|
    "<h2>#{l.work_id}</h2>" + l.string.gsub("\n", "<br>\n")
  end.join("\n")
end
