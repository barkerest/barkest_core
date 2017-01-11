
module BarkestCore

  ##
  # A namespaced controller just for testing the submenu.
  class TestsubController < ApplicationController

    def page1

    end

    def page2
      flash.now[:success] = 'The subheader should be above this message.'
    end

    def page3

    end

  end
end
