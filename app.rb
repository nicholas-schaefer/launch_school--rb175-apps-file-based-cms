require 'sinatra'
require 'sinatra/reloader'# unless ENV["RACK_ENV"] == "hack_test"# if (settings.development? || settings.test?)
# require "sinatra/content_for"

require "tilt/erubis"
require "redcarpet"
require 'pry'

def silly
  "silly"
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  enable :reloader
  # set :environment, :production
end

before do
  session[:user_is_authenticated]   ||= false
  session[:flash_messages]          ||= []
  session[:previous_path]           ||= ""
  session[:username]                ||= ""
  if !logged_in? && !(request.path_info == "/") && !(request.path_info == "/authentication/authenticate" && request.request_method == "POST")
    redirect "/"
  end
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

def log_in
  session[:user_is_authenticated] = true
end

def log_out
  session[:user_is_authenticated] = false
  session[:username] = ""
  session[:success] = "You have been signed out."
end

def logged_in?
  session[:user_is_authenticated]
end

def credentials_correct?(username_input, password_input)
  username_input == "admin" && password_input == "secret"
end

def data_path
  File.expand_path("../data", __FILE__)
  ENV["RACK_ENV"]
  if ENV["RACK_ENV"] == "hack_test"
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

# render markdown file extensions
# get /[\/].+[.]md/ do
#   headers \
#     "Content-Type" => "text/markdown"
#   body \
#     erb "markdown found!!!!"
#   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
#   markdown.render("# This will be a headline!")
# end

post '/authentication/authenticate' do
  session[:username] = params[:username]
  if credentials_correct?(params[:username], params[:password])
    log_in
    session[:success] = "Welcome!"
    redirect "/"
    # erb "<p>VICTORY</p><p>Username:#{params[:username]}</p><p>Password:#{params[:password]}</p>"
  else
    session[:error] = "Invalid Credentials."
    status 422
    redirect "/"
    # erb "<p>Failure</p><p>Username:#{params[:username]}</p><p>Password:#{params[:password]}</p>"
  end
end

post '/authentication/logout' do
  log_out

  redirect "/"
  # if credentials_correct?(params[:username], params[:password])
  #   session[:user_is_authenticated] = true
  #   session[:success] = "Welcome!"
  #   redirect "/"
  #   # erb "<p>VICTORY</p><p>Username:#{params[:username]}</p><p>Password:#{params[:password]}</p>"
  # else
  #   session[:error] = "Invalid Credentials."
  #   status 422
  #   redirect "/"
  #   # erb "<p>Failure</p><p>Username:#{params[:username]}</p><p>Password:#{params[:password]}</p>"
  # end
end

get '/' do
  # homepage()
  if logged_in?
    homepage()
  else
    erb :index_logged_out
  end
end

def handle_extension(absolute_path)
  case File.extname(absolute_path)
  when ".md" then render_extension_md(absolute_path)
  else            render_extension_txt(absolute_path)
  end
end

def render_extension_md(absolute_path)
  # headers \
  #   "Content-Type" => "text/html;charset=utf-8"
  # body \
  #   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  #   markdown.render(File.read(absolute_path))

  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  @markdown_file_as_html = markdown.render(File.read(absolute_path))
  body \
    erb :markdown
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

get '/new' do
  erb :new
end

get '/:file' do
  path = params[:file]
  absolute_path = File.join(data_path, path)

  # path_without_extension = File.basename(path, ".*")
  # if path_without_extension == "edit"
  #   erb "<p>edit request</p>"
  # end
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

#if there's an unsuccessful post request to /files/new, we still want page reloads to work
get '/files/new' do
  redirect '/new', 301
end

#http://127.0.0.1:4567/files/delete/hello.md.md
#if there's an successful post request to /files/delete/*, we still want page reloads to work
get '/files/delete/*.*' do
  redirect '/', 301
end


# Post request from form updating page text
post '/files/edit/:file' do
  path = params[:file]
  absolute_path = File.join(data_path, path)


  if File.exist?(absolute_path)
    # erb "<p>post request submitted to #{params[:file]}</p>"
    # @file = File.read(absolute_path)
    # @file_name = path
    # erb :edit

    File.open(absolute_path, mode = 'w') do |f|
      case File.extname(absolute_path)
      when ".md" then f.write(h(params[:editable_content]))
      else            f.write(params[:editable_content])
      end
    end

    session[:success] = "The file '#{params[:file]}' has been updated."
    redirect "/#{params[:file]}/edit"
  else
    #this ideally should be updated
    handle404_page_not_found(path)
  end
  # erb "<p>post request submitted to #{params[:file]}</p>"
end

# Post request from form updating page text
post '/files/new' do
  new_file_name = params[:new_doc]
  new_file_name = new_file_name.strip
  new_file_name = File.basename(new_file_name)
  file_extension = File.extname(new_file_name)

  absolute_path = File.join(data_path, new_file_name)

  if new_file_name.empty?
    session[:error] = "A name is required."
    status 422
    erb :new
    # session[:error] = "A name is required."
    # redirect '/new'
  elsif file_extension.empty?
    session[:error] = "An extension is required."
    status 422
    erb :new
  else
    if File.exist?(absolute_path)
      session[:error] = "Unable to create file, file already exists"
      redirect '/new'
    end

    if File.open(absolute_path, "w")
      session[:success] = "#{h(new_file_name)} was created."
      redirect "/"
    else
      session[:error] = "Unable to create file, invalid file path"
      redirect '/new'
    end
  end
end

# Post request from form deleting a file
post '/files/delete/:file' do
  path = params[:file]
  absolute_path = File.join(data_path, path)

  if File.exist?(absolute_path)
    File.delete(absolute_path)

    session[:success] = "The file '#{params[:file]}' has been deleted."
    status 302
    homepage
    # redirect "/"
  else
    #this ideally should be updated
    handle404_page_not_found(path)
  end
  # erb "<p>post request submitted to #{params[:file]}</p>"
end

