require 'bundler/setup'
require 'sinatra'
require 'data_mapper'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

class Post
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :body, Text
    property :created_at, DateTime
end

DataMapper.finalize
Post.auto_upgrade!

get '/' do
  erb :index
end

get '/posts' do
  @posts = Post.all(:order => [ :id.desc ], :limit => 20)
  erb :posts
end
