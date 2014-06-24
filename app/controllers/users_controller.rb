class UsersController < ApplicationController
  before_filter :get_user, except: [:new, :create]
  
  #[GET] /user/new
  def new
    @user = User.new
    
  end
  
  #[PATCH] /user/
  def create

    uprm = params[:user]
    unless @user = User.first(name: uprm[:name])
      @user = User.create!(name:uprm[:name])
      @user.prime_reviews(10)
    end

    session[:name] = @user.name
    session[:user_id] = @user._id

    redirect_to controller: :picks, action: :new
  end

  def logout
    session.delete(:name)
    session.delete(:user_id)

    redirect_to action: :new
  end
  
end
