require 'sinatra'
require 'sinatra/reloader' if development?
# require "sinatra/content_for"

require "tilt/erubis"
require 'pry'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end


before do
  ROOT = File.expand_path("..", __FILE__)
  session[:flash_messages]  ||= []
  session[:previous_path] ||= ""
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def hattr(text)
    Rack::Utils.escape_path(text)
  end

  def base_name(full_path)
    File.basename(full_path)
  end
end

def homepage()
  @error = session[:flash_messages].delete_at(0)
  # session[:previous_path] = "muffin"

  paths = Dir["#{ROOT}/data/*"]
  @files = paths.select { |path| File.file?(path)}

  body erb :index
end

get '/' do
  # status_code = session[:flash_messages].empty? ? 200 : 404
  homepage()
end

get '/:file' do
  @path = params[:file]
  absolute_path = ROOT + "/data/" + @path
  # "<p>this route works!</p>"

  if File.exist?(absolute_path)
    headers \
      "Content-Type" => "text/plain"
    body \
      File.read(absolute_path)
  else
    session[:previous_path] = @path
    session[:flash_messages][0] = "#{@path} does not exist."

    status 404
    redirect "/"
    # status    404
    # body      homepage()

    # headers
    # body      erb :page_not_found
    # body      erb :index

  end
end


# File.file?(paths[-1])


# Dir["./data/*"]
# => ["./data/about.txt", "./data/changes.txt", "./data/history.txt"]

# Dir.entries("./data")
# => ["..", "about.txt", "history.txt", "changes.txt", "."]
