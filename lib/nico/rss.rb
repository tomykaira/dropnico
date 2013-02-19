require 'lib/nico/agent'

module Nico
  class RSS
    def self.from_list(list)
      self.new("http://www.nicovideo.jp/mylist/#{list}?rss=1.0")
    end

    def initialize(url)
      @agent = Nico::Agent.new
      @url = url
    end

    def fetch_files
      safe_fetch_content.items.map do |item|
        item.link =~ /^http.*\/watch\/(.*)/
        $1
      end
    end

    def safe_fetch_content
      return @content if @content
      retry_at_most(3) do
        @content = fetch_content
      end
    end

    def fetch_content
      @agent.login
      thread_logger.info "get rss data: #{@url}"
      page = @agent.get @url
      ::RSS::Parser.parse(page.body, true)
    end
  end
end
