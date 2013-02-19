# _*_ coding: utf-8 _*_

# Copyright (c) 2011 Tomohiro Hashidate
# MIT License
# Acquired from https://github.com/joker1007/pasokara_player3

require "rss"
require "tmpdir"
require 'lib/nico/agent'

class NicoDownloader
  attr_accessor :agent

  def initialize(logger)
    @agent = Nico::Agent.new(logger)
    @logger = logger
    @error_count = 0
    @rss_error_count = 0
  end

  def get_rss(rss_url)
    begin
      @agent.login
      @logger.info "get rss data: #{rss_url}"
      page = @agent.get rss_url
      RSS::Parser.parse(page.body, true)
    rescue Exception
      @logger.fatal "get rss data failed: #{rss_url} #{$!}"
      @rss_error_count += 1
      raise "rss get error"
    end
  end

  def get_nico_list(nico_list)
    get_rss(nico_list.url) if nico_list.download
  end

  def get_flv_url(nico_name)
    begin
      page = @agent.get_api("/getflv/#{nico_name}")
      params = Hash[page.body.split("&").map {|value| value.split("=")}]
      url = URI.unescape(params["url"])
      @logger.info "download url => #{url}"
      return url
    rescue Exception
      @logger.fatal "api access error: #{nico_name} #{$!}"
      @error_count += 1
      raise "api error"
    end
  end

  def get_info(nico_name)
    begin
      page = @agent.get_api("/getthumbinfo/#{nico_name}")
      @logger.info "movie info download completed: #{nico_name}"
      page.body
    rescue Exception
      @logger.fatal "api access error: #{nico_name} #{$!}"
      @error_count += 1
      raise "api error"
    end
  end

  def download(nico_name, dir)
    @agent.login
    @logger.info "download sequence start: #{nico_name}"
    url = get_flv_url(nico_name)

    video_type_table = {"v" => "flv", "m" => "mp4", "s" => "swf"}
    url =~ /^http.*(?:nicovideo|smilevideo)\.jp\/smile\?(\w)=.*/
    video_type = video_type_table[$1] ? video_type_table[$1] : "flv"
    @logger.info "download file type => #{video_type}"
    if video_type == "swf"
      @logger.info "Not download swf file"
      return
    end


    begin
      @agent.get("http://www.nicovideo.jp/watch/#{nico_name}")
    rescue Exception
      @logger.fatal "movie page load error: #{nico_name} #{$!}"
      @error_count += 1
      raise "movie page load error"
    end

    path = File.join(dir, "#{nico_name}.#{video_type}")
    begin
      @logger.info "download start: #{nico_name} to #{path}"
      File.open(path, "wb:ASCII-8BIT") do  |file|
        file.write @agent.get_file(url)
      end
      @logger.info "download completed: #{nico_name}"
    rescue Exception
      @logger.fatal "download failed: #{nico_name} #{$!}"
      @logger.fatal "#{$@}"
      @error_count += 1
      raise "download failed"
    end

    sleep 5

    info_path = File.join(dir, "#{nico_name}_info.xml")
    begin
      info = get_info(nico_name)
      File.open(info_path, "wb:ASCII-8BIT") do  |file|
        file.write info
      end
    rescue Exception
      @logger.fatal "info download failed: #{nico_name} #{$!}"
      @logger.fatal "#{$@}"
      @error_count += 1
      raise "download failed"
    end

    @logger.info "download sequence completed: #{nico_name}"
    @error_count = 0
  end

  def rss_download(rss_url, dir)
    begin
      rss = get_rss(rss_url)
      @rss_error_count = 0
    rescue
      if @rss_error_count > 0 and @rss_error_count <= 3
        @logger.debug "Sleep 10 seconds"
        sleep 10
        @logger.info "Retry #{rss_url}"
        retry
      else
        return false
      end
    end

    rss.items.each do |item|
      item.link =~ /^http.*\/watch\/(.*)/
      nico_name = $1
      begin
        next if nico_name[0, 2] == "nm"
        @agent.history.clear
        download(nico_name, dir)
      rescue
        if @error_count > 0 and @error_count <= 3
          @logger.debug "Sleep 10 seconds"
          sleep 10
          @logger.info "Retry #{nico_name}"
          retry
        end
      end
      @error_count = 0
      @logger.debug "Sleep 7 seconds"
      sleep 7
    end
  end
end
