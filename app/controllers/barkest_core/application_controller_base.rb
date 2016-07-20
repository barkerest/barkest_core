module BarkestCore
  ##
  # This is the default application controller for the Barkest library.
  # The application's ApplicationController should inherit from this.
  class ApplicationControllerBase < ActionController::Base

    include BarkestCore::SessionsHelper
    include BarkestCore::RecaptchaHelper
    include BarkestCore::StatusHelper

    protect_from_forgery with: :exception
    layout 'layouts/application'
    helper BarkestCore::Engine.helpers

    ##
    # Should we show the denial reason when a user cannot access an action?
    #
    # Override this for any controller you want to show the denial reasons on.
    def show_denial_reason?
      false
    end

    ##
    # Authorize the current action.
    #
    # * If +group_list+ is not provided or only contains +false+ then any authenticated user will be authorized.
    # * If +group_list+ contains +true+ then only system administrators will be authorized.
    # * Otherwise the +group_list+ contains a list of accepted groups that will be authorized.
    #   Any user with one or more groups from the list will be granted access.
    def authorize!(*group_list)
      begin

        # an authenticated user must exist.
        unless logged_in?
          store_location

          raise_authorize_failure "You need to login to access '#{request.fullpath}'.",
                                  'nobody is logged in',
                                  false

          redirect_to login_url and return false
        end

        # clean up the group list.
        group_list ||= []
        group_list.delete false
        group_list.delete ''

        if group_list.include?(true)
          # group_list contains "true" so only a system admin may continue.
          unless system_admin?
            if show_denial_reason?
              flash[:info] = 'The requested path is only available to system administrators.'
            end
            raise_authorize_failure "Your are not authorized to access '#{request.fullpath}'.",
                                    'requires system administrator'
          end
          log_authorize_success 'user is system admin'

        elsif group_list.blank?
          # group_list is empty or contained nothing but empty strings and boolean false.
          # everyone can continue.
          log_authorize_success 'only requires authenticated user'

        else
          # the group list contains one or more authorized groups.
          # we want them to all be uppercase strings.
          group_list = group_list.map{|v| v.to_s.upcase}.sort
          result = current_user.has_any_group?(*group_list)
          unless result
            message = group_list.join(', ')
            if show_denial_reason?
              flash[:info] = "The requested path requires one of these groups: #{message}"
            end
            raise_authorize_failure "You are not authorized to access '#{request.fullpath}'.",
                                    "requires one of: #{message}"
          end
          log_authorize_success "user has '#{result}' group"
        end

      rescue BarkestCore::AuthorizeFailure => err
        flash[:danger] = err.message
        redirect_to root_url and return false
      end
      true
    end


    private

    def raise_authorize_failure(message, log_message = nil, raise_error = true)
      log_message ||= message
      Rails.logger.info "AUTH(FAILURE): #{request.fullpath}, #{current_user}, #{message}"
      raise BarkestCore::AuthorizeFailure.new(message) if raise_error
    end

    def log_authorize_success(message)
      Rails.logger.debug "AUTH(SUCCESS): #{request.fullpath}, #{current_user}, #{message}"
    end

  end
end