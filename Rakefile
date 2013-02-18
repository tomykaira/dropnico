$LOAD_PATH << File.dirname(__FILE__)

require 'logger'

require 'lib/dropbox_uploader'
require 'lib/youtube_downloader'

# this include "dropbox:authorize" task
require "dropbox-api/tasks"
Dropbox::API::Tasks.install

task 'dropbox:test' do
  uploader = DropboxUploader.new
  uploader.upload
end

task 'youtube:test' do
  logger = Logger.new STDOUT
  YoutubeFile.new(logger, "m6tnqKsqbFQ").download
end
