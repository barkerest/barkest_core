
##
# A fairly simple system status controller.
#
# The status system revolves around the GlobalStatus class and the WorkPath#system_status_file contents.
# When a long running process acquires a lock with the GlobalStatus, then it can update the status freely
# until it releases the lock.  This controller simply checks the GlobalStatus lock and reads the
# WorkPath#system_status_file contents to construct the object that gets returned to the client.
#
# See the methods below for more information on how this works.
#
class StatusController < ApplicationController

  before_action :check_for_user

  ##
  # Gets the current system status from the beginning of the system status log.
  #
  # Status is returned as a JSON object to be consumed by Javascript.
  #
  # error::
  #         The +error+ field alerts the consumer to any application error that may have occurred.
  #
  # locked::
  #         The +locked+ field lets the consumer know whether the system is currently busy with a
  #         long running task.
  #
  # status::
  #         The +status+ field gives the main status for the system at the time of the request.
  #
  # percentage::
  #         The +percentage+ field gives the progress for the current system status.
  #         If blank, there is no reported progress and the consumer should hide the progress bar.
  #         If set to '-', and +locked+ is false, then the consumer should decide whether
  #         to show the percentage (100%) or keep the progress bar hidden.
  #         If set to an integer between 0 and 100, then the consumer should show the progress bar
  #         with the specified percentage.
  #
  # contents::
  #         The +contents+ field contains the status log file up to this point.
  #         Requests to #first will contain the entire log file, whereas subsequent requests to
  #         #more will contain any data added to the log file since #first or #more was last
  #         requested.  The consumer should append the +contents+ field to its existing log to
  #         reconstruct the log data in entirety.
  #         If +error+ is true, then this will contain the error message and should be treated
  #         differently from the successful requests.
  def first
    self.start_position = 0
    build_status
    render json: @status.to_json
  end

  ##
  # Gets any status changes since the last call to +first+ or +more+.
  #
  # Status is returned as a JSON object to be consumed by Javascript.
  #
  # See #first for a description of the JSON object returned.
  def more
    build_status
    render json: @status.to_json
  end

  ##
  # Shows the dedicated status reporting page.
  #
  # This action should not be invoked directly, instead use the StatusHelper#show_system_status helper
  # method with the long running code as a block.
  def current
    @inital_status = BarkestCore::GlobalStatus.current[:message]
  end

  ##
  # Shows the status testing page.
  #
  # This page provides five examples of how to implement status display.
  def test
    flag = (params[:flag] || 'menu').underscore.to_sym

    if flag != :menu
      show_system_status(
          url_on_completion: status_test_url,
          completion_button: 'Test Again',
          main_status: 'Running test process'
      ) do |status|
        sleep 0.5

        File.open(BarkestCore::WorkPath.system_status_file, 'wt') do |f|
          2.times do |i|
            f.write("Before loop status message ##{i+1}.\n")
            f.flush
            sleep 0.1
          end
          sleep 0.5

          status.set_percentage(0) if flag == :with_progress
          15.times do |t|
            c = (t % 2 == 1) ? 3 : 5
            c.times do |i|
              f.write("Pass ##{t+1} status message ##{i+1}.\n")
              f.flush
              sleep 0.1
            end
            status.set_percentage((t * 100) / 15) if flag == :with_progress
            sleep 0.5
          end
        end
      end
    end
  end

  private

  def check_for_user
    authorize! true
  end

  def start_position
    session[:system_status_position] || 0
  end

  def start_position=(value)
    session[:system_status_position] = value
  end

  def build_status
    start = start_position

    cur = BarkestCore::GlobalStatus.current
    @status = { error: false, locked: cur[:locked], status: cur[:message], percentage: cur[:percent] }

    begin
      raise StandardError.new('No system status.') unless File.exist?(BarkestCore::WorkPath.system_status_file)

      File.open(BarkestCore::WorkPath.system_status_file, 'r') do |f|
        @status[:contents] = f.read
      end
      if start > 0 && @status[:contents].length >= start
        @status[:contents] = @status[:contents][start..-1]
      end
      start += @status[:contents].length
    rescue Exception => err
      @status[:contents] = err.message
      @status[:error] = true
    end

    self.start_position = start
  end

end
