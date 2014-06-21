class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  protected
  def get_user
    unless (uid = session[:user_id]) && (@user = User.find(uid) )
      redirect_to controller: :users, action: :new
    end
  end
end
