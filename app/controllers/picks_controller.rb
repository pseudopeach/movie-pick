class PicksController < ApplicationController
  before_filter :get_user
  
  #[GET] /pick/new
  def new
    @pick_count = @user.pick_count
    @choice_a, @choice_b = @user.next_choice_pair
  end
  
  #[POST] /pick
  def create
    winner_id = params[:pick]
    runnerup_id = params[:runnerup] || (params[:both].values - [winner_id]).first

    if @user.add_pick(winner_id, runnerup_id)
      flash[:notice] = "Pick saved."
      redirect_to action: :new
    else
      flash[:notice] = "Pick save failed."
      flash[:notice_type] = :error
      render :new
    end
  end
  
end
