module BarkestCore
  ##
  # This module contains some helper functions to make generating common HTML elements easier.
  module HtmlHelper

    ##
    # Creates a glyph icon using the specified +name+ and +size+.
    #
    # The +size+ can be nil, :small, :smaller, :big, or :bigger.
    # The default size is nil.
    def glyph(name, size = nil)
      size = size.to_s.downcase
      if %w(small smaller big bigger).include?(size)
        size = ' glyph-' + size
      else
        size = ''
      end
      "<i class=\"glyphicon glyphicon-#{h name}#{size}\"></i>".html_safe
    end

    ##
    # Creates a check glyph icon if the +bool_val+ is true.
    #
    # The +size+ can be nil, :small, :smaller, :big, or :bigger.
    # The default +size+ is :small.
    def check_if(bool_val, size = :small)
      glyph(:ok, size) if bool_val
    end

  end

end
