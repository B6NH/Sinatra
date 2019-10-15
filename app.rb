require 'bundler/setup'
require 'sinatra'
require 'data_mapper'

get '/' do
  erb :index
end
