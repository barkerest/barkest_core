##
# This is a simple controller that handles account activation requests.
#
class AccountActivationsController < ApplicationController

  ##
  # Takes in the user's email address and activation token as parameters.
  # If the activation token is correct for the email, then the account is activated.
  #
  def edit
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
