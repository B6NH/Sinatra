require 'bundler/setup'
require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'
require 'will_paginate'
require 'will_paginate/data_mapper'
require 'faker'
require "sinatra/cookies"
enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

class Post
    include DataMapper::Resource
    property :id, Serial
    property :title, String, :required => true
    property :body, Text, :required => true
    property :votes_up,    Integer
    property :votes_down,  Integer
    property :created_at, DateTime

    has n, :comments, constraint: :destroy
    has n, :categories, :through => Resource
end

class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :posted_by,  String, :required => true
  property :body,       Text, :required => true

  belongs_to :post
end

class Category
  include DataMapper::Resource

  property :id, Serial
  property :name,  String, :unique => true

  has n, :posts, :through => Resource
end


DataMapper.finalize
DataMapper.auto_upgrade!

Category.create(name:"Games")
Category.create(name:"Movies")
Category.create(name:"Music")
Category.create(name:"Sport")


def newPost(title,body)
  post = Post.new(
    title: title,
    body: body,
    votes_up: 0,
    votes_down: 0,
    created_at: Time.now
  )
end


# SEED DATABASE
if (Post.count < 5)
  10.times do
    post = newPost(Faker::Coffee.blend_name,Faker::Coffee.origin)
    post.save
  end
end



get '/' do
  erb :index
end

# SHOW ALL POSTS
get '/posts' do
  @posts = Post.paginate(page: params[:page], per_page: 3)
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
  post = newPost(params[:title],params[:body])

  if post.save
    flash[:notice] = "Post created"
    redirect '/posts'
  else
    flash[:error] = "Error"
    redirect back
  end
end


# UPDATE POST
put '/posts/:id' do
  post = Post.get(params[:id])

  if post.update(title:params[:title],body:params[:body])
    flash[:notice] = "Post updated"
    redirect '/posts'
  else
    flash[:error] = "Error"
    redirect back
  end
end


# DESTROY POST
delete '/posts/:id' do
  post = Post.get(params[:id])
  post.destroy
  flash[:notice] = "Post destroyed"
  redirect '/posts'
end


# CREATE COMMENT
post '/posts/:id/comments' do
  post = Post.get(params[:id])
  comment = post.comments.new(posted_by:params[:posted_by],body:params[:body])

  if comment.save
    flash[:notice] = "Comment created"
  else
    flash[:error] = "Error"
  end

  redirect back
end

# DESTROY COMMENT
delete '/posts/:post_id/comments/:comment_id' do
  comment = Comment.get(params[:comment_id])
  comment.destroy
  flash[:notice] = "Comment destroyed"
  redirect back
end


# RATE POST
put '/rate_post/:post_id' do
  vType = params[:_vote_type]
  id = params[:post_id]

  if(cookies["voted_#{id}"].nil?)
    post = Post.get(id)
    if(vType=="up")
      votes = post.votes_up
      post.update(votes_up:votes+1)
      flash[:notice] = "Upvoted"
    else
      votes = post.votes_down
      post.update(votes_down:votes+1)
      flash[:notice] = "Downvoted"
    end
    response.set_cookie("voted_#{id}", :value => true, :expires => Time.now + 3600*24)
  else
    flash[:error] = "Already voted"
  end
  redirect back
end

get '/settings' do
  erb :settings
end

put '/settings' do
  response.set_cookie(:color, :value => params[:color], :expires => Time.now + 3600*24)
  flash[:notice] = "Saved"
  redirect back
end

# STATISTICS
get '/statistics' do
  @number_of_posts = Post.count
  @number_of_comments = Comment.count
  erb :statistics
end
