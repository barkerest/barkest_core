module BarkestCore
  ##
  # An application controller base with a few modifications making it ideal for the parent class to engine controllers.
  class EngineControllerBase < ApplicationControllerBase

    # As an engine, we need to make sure the NotLoggedIn exception flows properly.
    # If we let this fall through, it looks for the route inside our engine.
    # We need to tell it to look at the main app instead.
    rescue_from NotLoggedIn do |exception|
      flash[:info] = exception.message
      redirect_to main_app.login_url
    end

  end
end