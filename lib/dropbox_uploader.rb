require 'dropbox-api'

Dropbox::API::Config.app_key    = ENV['DROPBOX_APP_KEY']
Dropbox::API::Config.app_secret = ENV['DROPBOX_APP_SECRET']
Dropbox::API::Config.mode       = "app_folder"

class DropboxUploader
  def initialize
    @client = Dropbox::API::Client.new(:token => ENV['DROPBOX_CLIENT_TOKEN'], :secret => ENV['DROPBOX_CLIENT_secret'])
  end

  def upload
    @client.upload("test.txt", "hoge")
  end
end
