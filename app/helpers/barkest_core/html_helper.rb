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

    ##
    # Creates a panel with the specified title.
    #
    # Valid options:
    #  *  +type+ can be +primary+, +success+, +info+, +warning+, or +danger+.   Default: primary
    #  *  +size+ can be any value from 1..12.   Default: 6
    #  *  +offset+ can be any value from 0..12.   Default: 3
    #  *  +open_body+ can be true or false.  If true, the body division is opened (and closed) by this helper.   Default: true
    #
    # Provide a block to render content within the panel.
    def panel(title, options = { }, &block)
      options = {
          type: 'primary',
          size: 6,
          offset: 3,
          open_body: true
      }.merge(options || {})

      options[:type] = options[:type].to_s.downcase
      options[:type] = 'primary' unless %w(primary success info warning danger).include?(options[:type])
      options[:size] = 6 unless (1..12).include?(options[:size])
      options[:offset] = 3 unless (0..12).include?(options[:offset])

      ret = "<div class=\"col-md-#{options[:size]} col-md-offset-#{options[:offset]}\"><div class=\"panel panel-#{options[:type]}\"><div class=\"panel-heading\"><h4 class=\"panel-title\">#{h title}</h4></div>"
      ret += '<div class="panel-body">' if options[:open_body]

      if block_given?
        content = capture { block.call }
        ret += h content.to_s
      end

      ret += '</div>' if options[:open_body]
      ret += '</div></div>'

      ret.html_safe
    end


  end

end
