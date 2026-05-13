class SetupController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    redirect_to root_path if User.any?
    @user = User.new
  end

  def create
    redirect_to root_path if User.any?
    
    @user = User.new(setup_params)
    @user.role = :admin # The first user is always an admin

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Admin account created successfully! Welcome to your Family Tree."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def setup_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
