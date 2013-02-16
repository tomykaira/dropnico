require 'dropbox-api'

Dropbox::API::Config.app_key    = ENV['DROPBOX_APP_KEY']
Dropbox::API::Config.app_secret = ENV['DROPBOX_APP_SECRET']

class DropboxUploader
  def initialize
    unless ENV['DROPBOX_CLIENT_TOKEN'] && ENV['DROPBOX_CLIENT_SECRET']
      raise "Dropbox authentication information is not provided"
    end
    @client = Dropbox::API::Client.new(:token => ENV['DROPBOX_CLIENT_TOKEN'], :secret => ENV['DROPBOX_CLIENT_SECRET'])
  end

  def upload
    @client.upload("test.txt", "hoge")
  end
end
