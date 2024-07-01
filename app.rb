require 'sinatra'
require 'sinatra/reloader'
require "tilt/erubis"
require 'pry'

before do
  ROOT = File.expand_path("..", __FILE__)
end


helpers do
  def base_name(full_path)
    File.basename(full_path)
  end
end

get '/' do
  paths = Dir["#{ROOT}/data/*"]
  @files = paths.select { |path| File.file?(path)}

  erb :index
end

get '/:file' do
  absolute_path = ROOT + "/data/" + params[:file]
  # "<p>this route works!</p>"

  if File.exist?(absolute_path)
    headers \
      "Content-Type" => "text/plain"
    body \
      File.read(absolute_path)
  else
    erb :page_not_found
  end
end


# File.file?(paths[-1])


# Dir["./data/*"]
# => ["./data/about.txt", "./data/changes.txt", "./data/history.txt"]

# Dir.entries("./data")
# => ["..", "about.txt", "history.txt", "changes.txt", "."]
