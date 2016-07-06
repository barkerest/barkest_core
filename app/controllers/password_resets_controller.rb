##
# This is a simple controller that processes user password reset requests.
#
class PasswordResetsController < ApplicationController
  before_action :load_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  ##
  # Shows the form allowing the user to enter their email address and confirm their non-robot status.
  #
  def new
  end

  ##
  # Verifies that the user is not a robot via recaptcha, once that is complete the submitted
  # email address is looked up.  Depending on the status of the user account looked up, one
  # of four actions will occur.
  #
  # 1. The user account is active and valid, a reset email is sent.
  # 2. The user account is disabled, a disabled account message is sent.
  # 3. The user account has not been activated, an inactive account message is sent.
  # 4. The user account doesn't exist, a non-existent account message is sent.
  #
  # Because a message is always sent, the caller cannot determine if the email address
  # is a valid user account.  If it is a valid attempt on a non-existent account,
  # only the recipient will know that the email address is not associated with an account
  # and will be able to work from there to create a new account.
  #
  def create
    unless verify_recaptcha_challenge
      flash.now[:danger] = 'You must complete the recaptcha challenge to reset your password.'
      render 'new' and return
    end
    email = params[:password_reset][:email].downcase
    unless email && User::VALID_EMAIL_REGEX.match(email)
      flash.now[:danger] = 'You must provide a valid email address to reset your password.'
      render 'new' and return
    end

    @user = User.find_by(email: email)
    if @user && @user.ldap?
      User.send_ldap_reset_email(email, request.remote_ip)
    elsif @user && @user.enabled? && @user.activated?
      @user.create_reset_digest
      @user.send_password_reset_email request.remote_ip
    elsif @user
      if !@user.enabled?
        User.send_disabled_reset_email(email, request.remote_ip)
      elsif !@user.active?
        User.send_inactive_reset_email(email, request.remote_ip)
      else
        User.send_missing_reset_email(email, request.remote_ip)
      end
    else
      User.send_missing_reset_email(email, request.remote_ip)
    end

    flash[:info] = 'An email with password reset information has been sent to you.'
    redirect_to root_url
  end

  ##
  # Shows a form allowing the user to specify a new password for their account.
  # This is of course after verifying that the email address is correct and the
  # password reset token for the email address is correct.
  #
  def edit

  end

  ##
  # Resets the user's password.  This is only done once the email address is
  # confirmed as being associated with a valid account, and the password reset
  # token provided matches that account.  The user must also complete a
  # recaptcha challenge to prevent robotic submissions, and the user's password
  # must not be blank.
  #
  def update
    if params[:user][:password].blank?
      @user.errors.add(:password, 'can\'t be blank')
      render 'edit'
    elsif !verify_recaptcha_challenge(@user)
      render 'edit'
    elsif @user.update_attributes(user_params)
      log_in @user
      flash[:success] = 'Password has been reset.'
      redirect_to @user
    else
      render 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def load_user
    @user = User.find_by(email: params[:email])
  end

  def valid_user
    unless @user && !@user.ldap? && @user.enabled? && @user.activated? && @user.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  def check_expiration
    if @user.password_reset_expired?
      flash[:danger] = 'Password reset request has expired.'
      redirect_to new_password_reset_url
    end
  end

end
