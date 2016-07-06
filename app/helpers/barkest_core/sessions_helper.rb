module BarkestCore
  ##
  # This module adds +log_in+, +log_out+, +current_user+, and other session related helper methods.
  #
  # Based on the tutorial from [www.railstutorial.org](www.railstutorial.org).
  module SessionsHelper

    ##
    # Logs in the given user.
    def log_in(user)
      session[:user_id] = user.id
    end

    ##
    # Logs out any currently logged in user.
    def log_out
      forget current_user
      session.delete(:user_id)
      @current_user = nil
    end

    ##
    # Gets the current user.
    def current_user
      if (user_id = session[:user_id])
        @current_user ||= User.find_by(id: user_id)
      elsif (user_id = cookies.signed[:user_id])
        user = User.find_by(id: user_id)
        if user && user.authenticated?(:remember, cookies[:remember_token])
          log_in user
          @current_user = user
        end
      end
    end

    ##
    # Is the specified user the current user?
    def current_user?(user)
      user == current_user
    end

    ##
    # Is the current user a system administrator?
    def system_admin?
      current_user && current_user.system_admin?
    end

    ##
    # Is a user currently logged in?
    def logged_in?
      !current_user.nil?
    end

    ##
    # Stores the user id to the permanent cookies to keep the user logged in.
    def remember(user)
      user.remember
      cookies.permanent.signed[:user_id] = user.id
      cookies.permanent[:remember_token] = user.remember_token
    end

    ##
    # Removes the user from the permanent cookies.
    def forget(user)
      user.forget
      cookies.delete(:user_id)
      cookies.delete(:remember_token)
    end

    ##
    # A helper redirect method primarily used after logon to redirect to the page that requested a logon.
    #
    # There may be other uses, but logon is the most likely use case.
    def redirect_back_or(default)
      redirect_to(session[:forwarding_url] || default)
      session.delete(:forwarding_url)
    end

    ##
    # Stores the current request URL to the session for use with +redirect_back_or+.
    #
    def store_location
      session[:forwarding_url] = request.url if request.get?
    end

    ##
    # Stores the current request URL to the session and redirects to the specified URL.
    def store_location_and_redirect_to(url)
      store_location
      redirect_to url
    end

  end
end
