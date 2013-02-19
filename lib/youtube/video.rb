# -*- coding: utf-8 -*-

require 'mechanize'
require 'json'
require 'lib/youtube/url'

module Youtube
  class Video
    def initialize(logger, video_id)
      @agent = Mechanize.new
      @logger = logger
      @video_id = video_id
    end

    def download(dir)
      begin
        unless @title
          fetch_video_info
        end
      rescue Exception => e
        @logger.fatal "info download failed: #{@video_id} #{$!}"
        @logger.fatal "#{$@}"
        raise e
      end

      begin
        @logger.info "Downloading #{filename}..."
        video = @agent.get(video_url.download_url)
        video.save_as(::File.join(dir, filename))
      rescue Exception => e
        @logger.fatal "video download failed: #{@video_id} #{$!}"
        @logger.fatal "#{$@}"
        raise e
      end
    end

    private

    def filename
      # Replace characters not allowed as a file name in Windows and Linux
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

      @urls = Url.parse_map(config['args']['url_encoded_fmt_stream_map'])
      @hash  = config['args']['t']
      @title = config['args']['title']
    end
  end
end
