# this shouldn't be necessary, but engines seem to have a few weak spots.
require 'will_paginate/view_helpers/action_view'
# removes a circular loading warning during testing
# while still allowing the styling during development/production
unless Rails.env.test?
  require 'bootstrap-will_paginate'
end

module BarkestCore
  ##
  # This module contains some generic helper functions for use in all views and all controllers.
  module ApplicationHelper

    ##
    # Generates a title string for a page using a standard format.
    #
    # In this case, the standard format is either 'application name' or 'application name - page specific title'.
    #
    # * +title+ Specifies the page specific title.
    #
    def page_title(title = nil)
      return Rails.application.app_name if title.blank?
      "#{Rails.application.app_name} - #{title}"
    end

    ##
    # Renders an error summary for the specified model.
    #
    # Any model that includes an +errors+ method that returns an +full_messages+ collection can be passed to this method.
    #
    # If more than 6 errors exist, then the first 3 will be shown with a link to display all of the error messages.
    #
    def error_summary(model)
      render partial: 'shared/error_messages', locals: { model: model }
    end

    ##
    # Renders an alert message.
    #
    # * +type+ The type of message [info, success, warn, error, danger, etc]
    # * +message+ The message to display.
    #
    # To provide messages including HTML, you need to prefix the type with 'safe_'.
    #
    #   render_alert(safe_info, '<strong>This</strong> is a message containing <code>HTML</code> content.')
    #
    # The message can be a string, hash, or array.  When an array is specified, then each array element is enumerated and
    # joined together.  The real power comes in when you specify a hash.  A hash will print the key as a label and then
    # enumerate the value (string, hash, or array) in an unordered list.  Hash values are processed recursively, allowing
    # you to create alerts with lists within lists.
    #
    #   render_alert(info, { 'Section 1' => [ 'Line 1', 'Line 2', 'Line 3' ] })
    #
    #   <label>Section 1</label>
    #   <ul>
    #     <li>Line 1</li>
    #     <li>Line 2</li>
    #     <li>Line 3</li>
    #   </ul>
    #
    #   render_alert(info, { 'Block A' => { 'Block A:1' => [ 'Line 1', 'Line 2' ] }})
    #
    #   <label>Block A</label>
    #   <ul>
    #     <li>
    #       <label>Block A:1</label>
    #       <ul>
    #         <li>Line 1</li>
    #         <li>Line 2</li>
    #       </ul>
    #     </li>
    #   </ul>
    #
    def render_alert(type, message)
      if type.to_s.index('safe_')
        type = type.to_s[5..-1]
        message = message.to_s.html_safe
      end

      type = type.to_sym

      type = :info if type == :notice
      type = :danger if type == :alert

      return nil unless [:info, :success, :danger, :warning].include?(type)

      "<div class=\"alert alert-#{type} alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>#{render_alert_message(message)}</div>".html_safe
    end

    private

    def render_alert_message(message, bottom = true)
      ret = ''
      if message.is_a?(Array)
        message = message.map { |v| render_alert_message(v, bottom) }
        ret += message.join
      elsif message.is_a?(Hash)
        message.each do |k,v|
          ret += '<li>' unless bottom
          ret += "<label>#{h k.to_s}</label>"
          ret += "<ul>#{render_alert_message(v, false)}</ul>"
          ret += '</li>' unless bottom
        end
      else
        if bottom
          ret += h(message)
        else
          ret += "<li>#{h message}</li>".html_safe
        end
      end
      ret.html_safe
    end


  end
end
