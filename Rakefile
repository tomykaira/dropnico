$LOAD_PATH << File.dirname(__FILE__)
require 'lib/dropbox_uploader'

# this include "dropbox:authorize" task
require "dropbox-api/tasks"
Dropbox::API::Tasks.install

task 'dropbox:test' do
  uploader = DropboxUploader.new
  uploader.upload
end
