require 'dropbox-api'

Dropbox::API::Config.app_key    = ENV['DROPBOX_APP_KEY']
Dropbox::API::Config.app_secret = ENV['DROPBOX_APP_SECRET']

class DropboxUploader
  def initialize
    unless ENV['DROPBOX_CLIENT_TOKEN'] && ENV['DROPBOX_CLIENT_SECRET']
      thread_logger.fatal "Dropbox authentication information is not provided"
      raise "Dropbox authentication information is not provided"
    end
    @client = Dropbox::API::Client.new(:token => ENV['DROPBOX_CLIENT_TOKEN'], :secret => ENV['DROPBOX_CLIENT_SECRET'])
    @client.connection.consumer.http.open_timeout = 300
    @client.connection.consumer.http.read_timeout = 300
  end

  def upload_file(file_path)
    content = File.read(file_path, mode: "rb")
    thread_logger.info "Uploading #{file_path}"
    @client.upload(File.basename(file_path), content)
    thread_logger.info "Done!"
  end

  def upload_directory(dir)
    Dir[dir + "/**/*"].each do |path|
      upload_file(path)
    end
  end
end
