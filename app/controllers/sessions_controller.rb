##
# A simple controller providing the login and logout methods for the application.
class SessionsController < ApplicationController

  before_action :require_anon, only: [ :new, :create ]

  ##
  # Shows the login form.
  #
  def new
  end

  ##
  # Attempts to login a user.  To successfully log in, a user must be activated and enabled.
  #
  # A disabled user is treated the same as a non-existent user or an invalid password,
  # a generic message stating invalid email or password is shown.
  # An non-activated user is given a message indicating their account is not yet active.
  #
  # Upon successfuly login, the user is redirected back to where they came from or to the
  # root url.
  #
  def create
    if (@user = BarkestCore::UserManager.authenticate(params[:session][:email], params[:session][:password], request.remote_ip))
      if @user.activated?
        # log the user in.
        log_in @user
        params[:session][:remember_me] == '1' ? remember(@user) : forget(@user)

        # show alerts on login.
        session[:show_alerts] = true

        redirect_back_or @user
      else
        flash[:safe_warning] = 'Your account has not yet been activated.<br/>Check your email for the activation link.'
        redirect_to root_url
      end
    else
      # deny login.
      flash.now[:danger] = 'Invalid email or password.'
      render 'new'
    end
  end

  ##
  # Logs out any currently logged in user session.
  #
  # This will not raise errors if a user is not logged in and will redirect to the
  # root url when finished.
  #
  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  private

  def require_anon
    if logged_in?
      flash[:danger] = 'You are already logged in.'
      redirect_to root_url
    end
  end
end
