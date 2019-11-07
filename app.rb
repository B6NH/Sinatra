require 'bundler/setup'
require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'
require 'will_paginate'
require 'will_paginate/data_mapper'
require 'faker'
require 'sinatra/cookies'
require 'bcrypt'
enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

class Post
    include DataMapper::Resource
    property :id, Serial
    property :title, String, :required => true, :length => 1..30
    property :body, Text, :required => true, :length => 1..160
    property :votes_up,    Integer, :default => 0
    property :votes_down,  Integer, :default => 0
    property :created_at, DateTime, :default => Time.now.to_datetime

    has n, :comments, constraint: :destroy
    has n, :categories, :through => Resource, constraint: :skip
end

class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :author,  String, :required => true, :length => 1..30
  property :body,       Text, :required => true, :length => 1..160

  belongs_to :post
end

class Category
  include DataMapper::Resource

  property :id, Serial
  property :name,  String, :unique => true, :length => 1..30

  has n, :posts, :through => Resource, constraint: :skip
end

class User
  include DataMapper::Resource

  property :id,    Serial
  property :name , String, :required => true, :unique => true, :length => 1..30
  property :password , Text, :required => true
  property :admin, Boolean, :default => false
end


DataMapper.finalize
DataMapper.auto_upgrade!

mpass = BCrypt::Password.create("magda123")
epass = BCrypt::Password.create("ewa123")

User.create(name:"Magda",password:mpass)
User.create(name:"Ewa",password:epass)

Category.create(name:"games")
Category.create(name:"movies")
Category.create(name:"music")
Category.create(name:"sport")

def setFlashErrors(model)
  errors = []
  model.errors.each do |err|
    errors << err[0]
  end
  flash[:errors] = errors
end


# SEED DATABASE
if (Post.count < 5)
  10.times do
    post = Post.new(title:Faker::Coffee.blend_name,body:Faker::Coffee.origin)
    post.save
  end
end


post = Post.first
games = Category.first(name:"games")
sport = Category.first(name:"sport")
music = Category.first(name:"music")
post.categories << games
post.categories << sport
post.save
post = Post.get(2)
post.categories << games
post.categories << music
post.save



get '/' do
  erb :index
end

# SHOW ALL POSTS
get '/posts' do
  p_order = params[:order]
  p_title = params[:title]
  ord = p_order.nil?||p_order=='asc' ? :title : :title.desc
  @posts = Post.all(:order => [ ord ], :title.like => "%#{p_title}%").paginate(page: params[:page], per_page: 3)
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
  post = Post.new(title:params[:title],body:params[:body])

  if post.save
    flash[:notice] = "Post created"
    redirect '/posts'
  else
    setFlashErrors(post)
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
    setFlashErrors(post)
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
  comment = post.comments.new(author:params[:author],body:params[:body])

  if comment.save
    flash[:notice] = "Comment created"
  else
    setFlashErrors(comment)
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
    flash[:errors] = ["Already voted"]
  end
  redirect back
end

# SHOW SETTINGS
get '/settings' do
  erb :settings
end

# UPDATE SETTINGS
put '/settings' do
  response.set_cookie(:color, :value => params[:color], :expires => Time.now + 3600*24)
  flash[:notice] = "Saved"
  redirect back
end

# SHOW ALL CATEGORIES
get '/categories' do
  @categories = Category.all
  erb :categories
end

# SHOW POSTS FROM CATEGORY
get '/category/:name' do
  @category = Category.first(name:params[:name])
  @posts = @category.posts
  erb :category_posts
end

get '/login' do
  erb :login
end

post '/login' do
  name = params[:name]
  user = User.first(name:name)
  if(user.nil?||!(BCrypt::Password.new(user.password)==params[:password]))
    flash[:error] = "Incorrect name or password"
    redirect back
  else
    session[:user] = name
    redirect '/profile'
  end
end

get '/register' do
  erb :register
end

post '/register' do
  if(params[:password]!=params[:password2])
    flash[:errors] = ["Passwords dont match"]
    redirect back
  else
    hash = BCrypt::Password.create(params[:password])
    user = User.new(name:params[:name],password:hash)

    if user.save
      flash[:notice] = "User created"
      redirect '/posts'
    else
      setFlashErrors(user)
      redirect back
    end
  end
end

get '/profile' do
  if(session[:user].nil?)
    redirect '/login'
  else
    @user = User.first(name:session[:user])
    erb :profile
  end
end

get '/logout' do
  session[:user] = nil
  redirect '/login'
end

# STATISTICS
get '/statistics' do
  @number_of_posts = Post.count
  @number_of_comments = Comment.count
  erb :statistics
end
