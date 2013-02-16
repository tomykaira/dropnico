# _*_ coding: utf-8 _*_

# Copyright (c) 2011 Tomohiro Hashidate
# MIT License
# Acquired from https://github.com/joker1007/pasokara_player3

require "rss"
require "tmpdir"

class NicoDownloader
  attr_accessor :agent

  def agent_init
    @agent = Mechanize.new
    @agent.read_timeout = 30
    @agent.open_timeout = 30
    @agent.max_history = 0
    @agent.user_agent_alias = 'Windows Mozilla'
  end

  def initialize(logger)
    agent_init
    @logger = logger
    @mail = ENV['NICO_MAIL']
    @pass = ENV['NICO_PASS']
    @error_count = 0
    @rss_error_count = 0
  end

  def login?
    @agent.get("http://www.nicovideo.jp/").header["x-niconico-authflag"] != "0"
  end

  def login
    if @mail and @pass
      res = @agent.post 'https://secure.nicovideo.jp/secure/login?site=niconico','mail' => @mail,'password' => @pass
      res.header["x-niconico-authflag"] != "0"
    else
      @logger.fatal "Mail or pass is not set mail: #{@mail}, pass: #{@pass}"
      raise "Login Error"
    end
  end

  def get_rss(rss_url)
    begin
      login
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
      get_api = "http://www.nicovideo.jp/api/getflv/#{nico_name}"
      page = @agent.get get_api
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
      get_api = "http://www.nicovideo.jp/api/getthumbinfo/#{nico_name}"
      page = @agent.get get_api
      @logger.info "movie info download completed: #{nico_name}"
      page.body
    rescue Exception
      @logger.fatal "api access error: #{nico_name} #{$!}"
      @error_count += 1
      raise "api error"
    end
  end

  def download(nico_name, dir = tmpdir)
    login
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

    Dir.mkdir dir unless File.exist?(dir)
    movie_dir = File.join(dir, "#{nico_name}")
    Dir.mkdir movie_dir unless File.exist?(movie_dir)
    path = File.join(movie_dir, "#{nico_name}.#{video_type}")
    begin
      @logger.info "[INFO] download start: #{nico_name}"
      File.open(path, "wb:ASCII-8BIT") do  |file|
        file.write @agent.get_file(url)
      end
      create_thumbnail(path)
      @logger.info "[INFO] download completed: #{nico_name}"
    rescue Exception
      @logger.fatal "download failed: #{nico_name} #{$!}"
      @logger.fatal "#{$@}"
      @error_count += 1
      raise "download failed"
    end

    sleep 5

    info_path = File.join(movie_dir, "#{nico_name}_info.xml")
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

  def rss_download(rss_url, dir = tmpdir)
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

  def tmpdir
    File.join(Dir.tmpdir, Time.now.to_i)
  end
end
