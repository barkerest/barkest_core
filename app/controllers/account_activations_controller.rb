##
# This is a simple controller that handles account activation requests.
#
class AccountActivationsController < ApplicationController

  ##
  # Takes in the user's email address and activation token as parameters.
  #
  # If the activation token is correct for the email, then the account is activated.
  # If a user is logged in, then the user must be activated already, so alert them that reactivation is not allowed.
  def edit
    if logged_in?
      flash[:danger] = 'You cannot reactivate your account.'
      redirect_to root_url
    else
      user = User.find_by(email: params[:email].downcase)
      if user && !user.activated? && user.authenticated?(:activation, params[:id])
        user.activate
        log_in user
        flash[:success] = 'Your account has been activated.'
        redirect_to user
      else
        flash[:danger] = 'Invalid activation link'
        redirect_to root_url
      end
    end
  end

end
