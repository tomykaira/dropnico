# _*_ coding: utf-8 _*_

# Copyright (c) 2011 Tomohiro Hashidate
# MIT License
# Acquired from https://github.com/joker1007/pasokara_player3

require "rss"
require "tmpdir"
require 'lib/nico/agent'

module Nico
  class Video
    attr_reader :nico_name

    def initialize(nico_name, agent = nil)
      @nico_name = nico_name
      @agent = agent || Nico::Agent.new
    end

    def download(dir)
      @agent.login
      thread_logger.info "download sequence start: #{nico_name}"

      if video_type == "swf"
        thread_logger.info "Not download swf file"
        return
      end

      @agent.get("http://www.nicovideo.jp/watch/#{nico_name}")

      download_file(File.join(dir, "#{nico_name}.#{video_type}"))
      download_info(File.join(dir, "#{nico_name}_info.xml"))

      thread_logger.info "download sequence completed: #{nico_name}"
    end

    def download_info(path)
      page = @agent.get_api("/getthumbinfo/#{nico_name}")
      File.open(path, "wb:ASCII-8BIT") do  |file|
        file.write page.body
      end
      thread_logger.info "movie info download completed: #{nico_name}"
    end

    def download_file(path)
      thread_logger.info "download start: #{nico_name} to #{path}"
      File.open(path, "wb:ASCII-8BIT") do  |file|
        file.write @agent.get_file(flv_url)
      end
      thread_logger.info "download completed: #{nico_name}"
    end

    def flv_url
      return @url if @url
      page = @agent.get_api("/getflv/#{nico_name}")
      params = Hash[page.body.split("&").map {|value| value.split("=")}]
      @url = URI.unescape(params["url"])
      thread_logger.info "download url => #{@url}"
      @url
    end

    def video_type
      video_type_table = {"v" => "flv", "m" => "mp4", "s" => "swf"}
      flv_url =~ /^http.*(?:nicovideo|smilevideo)\.jp\/smile\?(\w)=.*/
      video_type = video_type_table[$1] ? video_type_table[$1] : "flv"
    end
  end
end
