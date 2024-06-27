require 'sinatra'
require 'sinatra/reloader'
require "tilt/erubis"

get '/' do
  # erb "Getting Started"
  erb :test
end
