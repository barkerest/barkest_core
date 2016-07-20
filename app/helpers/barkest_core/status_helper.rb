require 'spawnling'

module BarkestCore
  ##
  # This module contains helper methods related to status reporting.
  #
  module StatusHelper

    ##
    # Shows the system status while optionally performing a long running code block.
    #
    # Accepted options:
    #
    # url_on_completion::
    #     This is the URL you want to redirect to when the long running code completes.
    #     If not set, then the completion button will have an empty HREF which means it will simply reload the status page.
    #     It is therefore highly recommended that you provide this value when using this method.
    #
    # completion_button::
    #     This is the label for the button that becomes visible when the long running code completes.
    #     Defaults to 'Continue'.
    #
    # main_status::
    #     This is the initial status to report for the system when a long running code block is provided.
    #
    # If a code block is provided, this will reset the system status and spawn a thread to run the code block.
    # Before running the code block, it will acquire a GlobalStatus lock and set the initial status.
    # When the code block exits, either through error or normal behavior, the GlobalStatus lock will be released.
    #
    # It will yield the +status+ object to the code block on a successful lock, or it will yield false to the code
    # block to let it know that a lock could not be acquired.  You should check for this in your code block and
    # handle the error as appropriate.
    #
    # Example 1:
    #   def my_action
    #     Spawling.new do
    #       GlobalStatus.lock_for do |status|
    #         if status
    #           clear_system_status   # reset the log file.
    #           # Do something that takes a long time.
    #           ...
    #         end
    #       end
    #     end
    #     show_system_status(:url_on_completion => my_target_url)
    #   end
    #
    # Example 2:
    #   def my_action
    #     show_system_status(:url_on_completion => my_target_url) do |status|
    #       if status
    #         # Do something that takes a long time.
    #         ...
    #       end
    #     end
    #   end
    #
    # The benefits of Example 2 is that it handles the thread spawning and status locking for you.
    #
    def show_system_status(options = {})
      options = {
          url_on_completion: nil,
          completion_button: 'Continue',
          main_status: 'System is busy'
      }.merge(options || {})

      if block_given?
        clear_system_status
        Spawnling.new do
          status = BarkestCore::GlobalStatus.new
          if status.acquire_lock
            status.set_message options[:main_status]
            begin
              yield status
            ensure
              status.release_lock
            end
          else
            yield false
          end
        end
      end

      session[:status_comp_url] = options[:url_on_completion]
      session[:status_comp_lbl] = options[:completion_button]

      redirect_to status_current_url
    end

    ##
    # Clears the system status log file.
    #
    # If the file does not exist, it is created as a zero byte file.
    # This is important for the status checking, since if there is no log file it will report an error.
    #
    def clear_system_status
      unless BarkestCore::GlobalStatus.locked?
        # open, truncate, and close.
        File.open(BarkestCore::WorkPath.system_status_file,'w').close
      end
    end

    ##
    # Gets the URL to redirect to when the long running process completes.
    #
    def status_redirect_url
      session[:status_comp_url].to_s
    end

    ##
    # Gets the label for the button to show when the long running process completes.
    #
    def status_button_label
      session[:status_comp_lbl].to_s
    end

  end
end
