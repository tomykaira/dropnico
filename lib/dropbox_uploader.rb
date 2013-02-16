require 'dropbox-api'

Dropbox::API::Config.app_key    = ENV['DROPBOX_APP_KEY']
Dropbox::API::Config.app_secret = ENV['DROPBOX_APP_SECRET']

class DropboxUploader
  def initialize(logger)
    @logger = logger
    unless ENV['DROPBOX_CLIENT_TOKEN'] && ENV['DROPBOX_CLIENT_SECRET']
      @logger.fatal "Dropbox authentication information is not provided"
      raise "Dropbox authentication information is not provided"
    end
    @client = Dropbox::API::Client.new(:token => ENV['DROPBOX_CLIENT_TOKEN'], :secret => ENV['DROPBOX_CLIENT_SECRET'])
  end

  def upload_file(file_path)
    content = File.read(file_path, mode: "rb")
    @logger.info "Uploading #{file_path}"
    @client.upload(File.basename(file_path), content)
  end

  def upload_directory(dir)
    Dir[dir + "/**/*"].each do |path|
      upload_file(path)
    end
  end
end
