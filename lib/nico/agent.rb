require 'mechanize'

module Nico
  class Agent
    def initialize(logger)
      @logger = logger

      @mail = ENV['NICO_MAIL']
      @pass = ENV['NICO_PASS']

      @agent = Mechanize.new
      @agent.read_timeout = 30
      @agent.open_timeout = 30
      @agent.max_history = 0
      @agent.user_agent_alias = 'Windows Mozilla'
    end

    def login?
      @agent.get("http://www.nicovideo.jp/").header["x-niconico-authflag"] != "0"
    end

    def login
      return if login?
      if @mail and @pass
        res = @agent.post 'https://secure.nicovideo.jp/secure/login?site=niconico','mail' => @mail,'password' => @pass
        if res.header["x-niconico-authflag"] == "0"
          @logger.fatal "Failed to login #{rss}"
          raise "Login Error"
        end
      else
        @logger.fatal "Mail or pass is not set mail: #{@mail}, pass: #{@pass}"
        raise "Login Error"
      end
    end

    def get(*args)
      @agent.get(*args)
    end

    def get_file(*args)
      @agent.get_file(*args)
    end

    def get_api(path)
      path = '/' + path if path[0] != '/'
      get("http://www.nicovideo.jp/api#{path}")
    end
  end
end
