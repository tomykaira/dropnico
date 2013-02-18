# -*- coding: utf-8 -*-

require 'mechanize'
require 'json'
require 'lib/youtube_url'

class YoutubeDownloader
  def initialize(logger, video_id)
    @agent = Mechanize.new
    @logger = logger
    @video_id = video_id
  end

  def download(dir)
    unless @title
      fetch_video_info
    end

    # Replace characters not allowed as a file name in Windows and Linux
    @logger.info "Downloading #{filename}..."
    video = @agent.get(video_url.download_url)
    video.save_as(File.join(dir, filename))
  end

  private

  def filename
    @filename ||= @title.gsub(/[\<>:"\/|?* ]/, '-' ) + '.' + video_url.ext
  end

  def video_url
    @video_url = @urls.sort_by(&:video_resolution).last
  end

  def watch_url
    "http://www.youtube.com/watch?v=" + @video_id
  end

  def fetch_video_info
    response = @agent.get(watch_url)
    response.body =~ /yt.playerConfig\s*=\s*({.*})\s*;/
    json = $1

    unless json
      @logger.fatal "Failed to find playerConfig JSON object"
      raise "Failed to find playerConfig JSON object"
    end

    config = JSON.parse(json)

    @urls = YoutubeUrl.parse_map(config['args']['url_encoded_fmt_stream_map'])
    @hash  = config['args']['t']
    @title = config['args']['title']
  end
end
