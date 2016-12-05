##
# This is a user management controller.
#
# This includes all the actions necessary to create, list, edit, disable, and destroy users.
#
class UsersController < ApplicationController

  before_action :not_logged_in,   only: [ :new, :create ]
  before_action :logged_in_user,  except: [:new, :create]
  before_action :load_user,       except: [:index, :new, :create]
  before_action :correct_user,    only: [:edit, :update]
  before_action :admin_user,      only: [:destroy, :disable, :disable_confirm, :enable]
  before_action :not_current,     only: [:destroy, :disable, :disable_confirm, :enable]
  before_action :not_anon,        only: [:edit, :update, :destroy, :disable, :disable_confirm, :enable]
  before_action :not_ldap,        only: [:edit, :update]
  before_action :index_filter,    only: [:index]
  before_action :show_filter,     only: [:show]

  ##
  # Shows a list of all users.
  #
  # Admin users are shown all users including disabled and inactive.
  # Other users only see the enabled users.
  #
  def index
    @users = (current_user.system_admin? ? User.known.sorted : User.known.enabled.sorted).paginate(page: params[:page])
  end

  ##
  # Shows a specific user profile.
  #
  def show

  end

  ##
  # Shows the signup form for a new user.
  #
  def new
    @user = User.new
  end

  ##
  # Creates a new user account after verifying the user is not a robot.
  #
  def create
    @user = User.new(user_params)
    if @user.valid? && verify_recaptcha_challenge(@user)
      if @user.save
        @user.send_activation_email request.remote_ip
        flash[:safe_info] = 'Your account has been created, but needs to be activated before you can use it.<br/>Please check your email to activate your account.'
        redirect_to root_url and return
      end
    end
    render 'new'
  end

  ##
  # Shows a form to edit the user profile.
  #
  def edit

  end

  ##
  # Updates a user profile.
  #
  def update
    if @user.update_attributes(user_params)
      flash[:success] = 'Your profile has been updated.'
      redirect_to @user
    else
      render 'edit'
    end
  end

  ##
  # Destroys a user account that has been disabled for at least 15 days
  # as long as the requesting user is an admin.
  #
  def destroy
    if @user.enabled?
      flash[:danger] = 'Cannot delete an enabled user.'
    elsif @user.disabled_at.blank? || @user.disabled_at > 15.days.ago
      flash[:danger] = 'Cannot delete a user within 15 days of being disabled.'
    else
      @user.destroy
      flash[:success] = "User #{@user.name} has been deleted."
    end
    redirect_to users_path
  end

  ##
  # Shows a form requesting a reason to disable a user and allowing
  # the administrator a chance to cancel the action.
  #
  def disable_confirm
    load_disable_user
    unless @disable.user.enabled?
      flash[:warning] = "User #{@disable.user.name} is already disabled."
      redirect_to users_path
    end
  end

  ##
  # Disables a user account as long as the requesting user is an administrator
  # and provides a reason the account is being disabled.
  #
  def disable
    load_disable_user

    if @disable.valid?
      if @disable.user.disable(current_user, @disable.reason)
        flash[:success] = "User #{@disable.user.name} has been disabled."
        redirect_to users_path and return
      else
        @disable.errors.add(:user, 'was unable to be updated')
      end
    end

    render 'disable_confirm'
  end

  ##
  # Enables a previosly disabled user as long as the requesting user is an
  # administrator.
  #
  def enable
    if @user.enabled?
      flash[:warning] = "User #{@user.name} is already enabled."
      redirect_to users_path and return
    end

    if @user.enable
      flash[:success] = "User #{@user.name} has been enabled."
    else
      flash[:danger] = "Failed to enable user #{@user.name}."
    end

    redirect_to users_path
  end

  private

  # ensure we have an @user variable to work with.
  def load_user
    if system_admin?
      @user = User.find_by(id: params[:id])
    else
      @user = User.where(id: params[:id], enabled: true, activated: true).first
    end
    @user ||= User.new(name: 'Invalid User', email: 'invalid-email')
  end

  def load_disable_user
    @disable = DisableUser.new(params[:disable_user] ? disable_user_params : {})
    @disable.user = @user
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def disable_user_params
    params.require(:disable_user).permit(:reason)
  end

  def not_logged_in
    if logged_in?
      flash[:danger] = 'You are already logged in.'
      redirect_to root_url
    end
  end

  def logged_in_user
    unless logged_in?
      flash[:danger] = 'Please log in.'
      store_location_and_redirect_to login_url
    end
  end

  def correct_user
    # the current user can edit their details, so can an admin.
    redirect_to(root_url) unless current_user?(@user) || system_admin?
  end

  def admin_user
    redirect_to(root_url) unless system_admin?
  end

  def not_anon
    # anon user cannot be edited.
    redirect_to(root_url) if @user.anonymous?
  end

  def not_ldap
    if @user.ldap?
      flash[:danger] = 'LDAP accounts cannot be edited.'
      redirect_to @user
    end
  end

  def not_current
    if current_user?(@user)
      flash[:warning] = 'You cannot perform this operation on yourself.'
      redirect_to users_path
    end
  end

  def index_filter
    admin_user if BarkestCore.lock_down_users
  end

  def show_filter
    correct_user if BarkestCore.lock_down_users
  end

end
