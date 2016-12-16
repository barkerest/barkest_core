require 'time'

class LogViewController < ApplicationController

  before_action :valid_user
  before_action :load_options
  before_action :load_log

  def index
    @options.max_records = 50
  end

  private

  def valid_user
    authorize! true
  end

  def load_options
    @options = BarkestCore::LogViewOptions.new(
        params.include?(:barkest_core_log_view_options) ?
            params.require(:barkest_core_log_view_options).permit(:min_severity, :start_time, :end_time, :search) :
            { start_time: 7.days.ago }
    )
  end

  def load_log
    # load, filter, and reverse sort.
    @log = BarkestCore::LogEntry.read_log.keep_if{ |r| @options.keep_log_entry? r }.sort{ |a,b| b <=> a }
  end
end
