require 'sinatra'
require 'sinatra/reloader' if development?
# require "sinatra/content_for"

require "tilt/erubis"
require "redcarpet"
require 'pry'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
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

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def homepage()
  @error = session[:flash_messages].delete_at(0)

  pattern = File.join(data_path, "*")
  paths = Dir[pattern]

  @files = paths.select { |path| File.file?(path)}

  body erb :index
end

def file_type_markdown?
end

# render markdown file extensions
# get /[\/].+[.]md/ do
#   headers \
#     "Content-Type" => "text/markdown"
#   body \
#     erb "markdown found!!!!"
#   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
#   markdown.render("# This will be a headline!")
# end

get '/' do
  homepage()
end

get '/favicon.ico' do
  status 404
end

def handle_extension(absolute_path)
  case File.extname(absolute_path)
  when ".md" then render_extension_md(absolute_path)
  else            render_extension_txt(absolute_path)
  end
end

def render_extension_md(absolute_path)
  headers \
    "Content-Type" => "text/html;charset=utf-8"
  body \
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(File.read(absolute_path))
end

def render_extension_txt(absolute_path)
  headers \
    "Content-Type" => "text/plain"
  body \
    File.read(absolute_path)
end

def handle404_page_not_found(path)
  session[:previous_path] = path
  session[:flash_messages][0] = "#{path} does not exist."

  status 404
  redirect "/"
end

get '/:file' do
  path = params[:file]
  absolute_path = File.join(data_path, path)

  # path_without_extension = File.basename(path, ".*")
  # if path_without_extension == "edit"
  #   erb "<p>edit request</p>"
  # end
  # binding.pry
  if File.exist?(absolute_path)
    handle_extension(absolute_path)
  else
    handle404_page_not_found(path)
  end
end

get '/:file/edit' do
  path = params[:file]
  absolute_path = File.join(data_path, path)

  if File.exist?(absolute_path)
    @file = File.read(absolute_path)
    @file_name = path
    erb :edit
  else
    handle404_page_not_found(path)
  end
end

# Post request from form updating page text
post '/files/:file' do
  path = params[:file]
  absolute_path = File.join(data_path, path)


  if File.exist?(absolute_path)
    # erb "<p>post request submitted to #{params[:file]}</p>"
    # @file = File.read(absolute_path)
    # @file_name = path
    # erb :edit

    File.open(absolute_path, mode = 'w') do |f|
      f.write(params[:editable_content])
    end

    session[:success] = "The file '#{params[:file]}' has been updated."
    redirect "/#{params[:file]}/edit"
  else
    #this ideally should be updated
    handle404_page_not_found(path)
  end
  # erb "<p>post request submitted to #{params[:file]}</p>"
end


# File.file?(paths[-1])


# Dir["./data/*"]
# => ["./data/about.txt", "./data/changes.txt", "./data/history.txt"]

# Dir.entries("./data")
# => ["..", "about.txt", "history.txt", "changes.txt", "."]
