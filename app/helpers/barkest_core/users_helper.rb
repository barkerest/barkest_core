module BarkestCore
  ##
  # This module adds helper methods related to users in general (not just the current user).
  #
  # Based on the tutorial from [www.railstutorial.org](www.railstutorial.org).
  #
  module UsersHelper

    ##
    # Returns the Gravatar for the given user.
    #
    # Based on the tutorial from [www.railstutorial.org](www.railstutorial.org).
    #
    # The +user+ is the user you want to get the gravatar for.
    #
    # Valid options:
    # *   +size+ The size (in pixels) for the returned gravatar.  The gravatar will be a square image using this
    #     value as both the width and height.  The default is 80 pixels.
    # *   +default+ The default image to return when no image is set. This can be nil, :mm, :identicon, :monsterid,
    #     :wavatar, or :retro.  The default is :identicon.
    def gravatar_for(user, options = {})
      options = { size: 80, default: :identicon }.merge(options || {})
      options[:default] = options[:default].to_s.to_sym unless options[:default].nil? || options[:default].is_a?(Symbol)
      gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
      size = options[:size]
      default = [:mm, :identicon, :monsterid, :wavatar, :retro].include?(options[:default]) ? "&d=#{options[:default]}" : ''
      gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}#{default}"
      image_tag(gravatar_url, alt: user.name, class: 'gravatar', style: "width: #{size}px, height: #{size}px")
    end

  end
end
