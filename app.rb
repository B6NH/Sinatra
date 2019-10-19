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

    has n, :comments
end

class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :posted_by,  String
  property :body,       Text

  belongs_to :post
end

DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  erb :index
end

# SHOW ALL POSTS
get '/posts' do
  @posts = Post.all(:order => [ :id.desc ], :limit => 20)
  erb :posts
end

# NEW POST FORM
get '/posts/new' do
  erb :posts_new
end

# SHOW POST
get '/posts/:id' do
  @post = Post.get(params[:id])
  erb :posts_show
end

# EDIT POST FORM
get '/posts/:id/edit' do
  @post = Post.get(params[:id])
  erb :posts_edit
end

# CREATE POST
post '/posts' do
  Post.create(
    :title      => params[:title],
    :body       => params[:body],
    :created_at => Time.now
  )
  redirect '/posts'
end


# UPDATE POST
put '/posts/:id' do
  post = Post.get(params[:id])
  post.update(title:params[:title],body:params[:body])
  redirect '/posts'
end


# DESTROY POST
delete '/posts/:id' do
  post = Post.get(params[:id])
  post.destroy
  redirect '/posts'
end


# CREATE COMMENT
post '/posts/:id/comments' do
  post = Post.get(params[:id])
  post.comments.create(
    :posted_by  => params[:posted_by],
    :body       => params[:body]
  )
  redirect "/posts/#{params[:id]}"
end

# DESTROY COMMENT
delete '/posts/:post_id/comments/:comment_id' do
  comment = Comment.get(params[:comment_id])
  comment.destroy
  redirect "/posts/#{params[:post_id]}"
end
