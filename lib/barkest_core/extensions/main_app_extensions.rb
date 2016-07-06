
module BarkestCore
  ##
  # Gives the ability to hunt for a 'main_app' helper if a URL helper is missing.
  module MainAppUrlHelper

    # :nodoc:
    def self.included(base)
      base.class_eval do

        # :nodoc:
        alias :barkest_core_original_method_missing :method_missing

        # :nodoc:
        def method_missing(method, *args, &block)

          if respond_to?(:main_app)
            main_app = send(:main_app)
            if main_app && main_app.respond_to?(method)
              return main_app.send(method, *args, &block)
            end
          end

          barkest_core_original_method_missing(method, *args, &block)
        end

      end
    end

  end
end

ActionController::Base.include BarkestCore::MainAppUrlHelper
ActionMailer::Base.include BarkestCore::MainAppUrlHelper
ActionView::Base.include BarkestCore::MainAppUrlHelper
