module BarkestCore
  ##
  # An interface to a global status/lock file.
  #
  # The global status/lock file is a simple two line file.
  # The first line is the global status message.
  # The second line is the global status progress.
  #
  # The real magic comes when we take advantage of exclusive locks.
  # The process that will be managing the status takes an exclusive lock on the status/lock file.
  # This prevents any other process from taking an exclusive lock.
  # It does not prevent other processes from reading from the file.
  #
  # So the main process can update the file at any time, until it releases the lock.
  # The other processes can read the file at any time, and test for the lock state to determine if the main
  # process is still busy.
  #
  #
  class GlobalStatus

    ##
    # The exception raised in the +lock_for+ method when +raise_on_failure+ is set.
    FailureToLock = Class.new(StandardError)

    ##
    # Creates a new GlobalStatus object.
    #
    # If you specify a status file, then that file will be used for the locking and status reporting.
    # Otherwise, the "global_lock" file will be used.
    def initialize(status_file = nil)
      @lock_handle = nil
      @stat_handle = nil
      @status_file_path = status_file
    end

    ##
    # Gets the path to the global status file.
    def status_file_path
      @status_file_path ||= WorkPath.path_for('global_status')
    end

    ##
    # Gets the path to the global lock file.
    def lock_file_path
      @lock_file_path ||= WorkPath.path_for('global_lock')
    end

    ##
    # Determines if this instance has a lock on the status/lock file.
    def have_lock?
      !!@lock_handle
    end

    ##
    # Determines if any process has a lock on the status/lock file.
    def is_locked?
      begin
        return true if have_lock?
        return true unless acquire_lock
      ensure
        release_lock
      end
      false
    end

    ##
    # Gets the current status message from the status/lock file.
    def get_message
      get_status[:message]
    end

    ##
    # Gets the current progress from the status/lock file.
    def get_percentage
      r = get_status[:percent]
      r.blank? ? nil : r.to_i
    end

    ##
    # Gets the current status from the status/lock file.
    #
    # Returns a hash with three elements:
    #
    # message::
    #   The current status message.
    #
    # percent::
    #   The current status progress.
    #
    # locked::
    #   The current lock state of the status/lock file. (true for locked, false for unlocked)
    #
    def get_status
      r = {}
      if have_lock?
        @stat_handle.rewind
        r[:message] = (@stat_handle.eof? ? 'The current process is busy.' : @stat_handle.readline.strip)
        r[:percent] = (@stat_handle.eof? ? '' : @stat_handle.readline.strip)
        r[:locked] = true
      elsif is_locked?
        if File.exist?(status_file_path)
          begin
            File.open(status_file_path, 'r') do |f|
              r[:message] = (f.eof? ? 'The system is busy.' : f.readline.strip)
              r[:percent] = (f.eof? ? '' : f.readline.strip)
            end
          rescue
            r[:message] = 'The system appears busy.'
            r[:percent] = ''
          end
        else
          r[:message] = 'No status file.'
          r[:percent] = ''
        end
        r[:locked] = true
      else
        r[:message] = 'The system is no longer busy.'
        r[:percent] = '-'
        r[:locked] = false
      end
      r
    end

    ##
    # Sets the status message if this instance has a lock on the status/lock file.
    #
    # Returns true after successfully setting the message.
    # Returns false if this instance does not currently hold the lock.
    #
    def set_message(value)
      return false unless have_lock?
      cur = get_status
      set_status(value, cur[:percent])
    end

    ##
    # Sets the status progress if this instance has a lock on the status/lock file.
    #
    # Returns true after successfully setting the progress.
    # Returns false if this instance does not currently hold the lock.
    #
    def set_percentage(value)
      return false unless have_lock?
      cur = get_status
      set_status(cur[:message], value)
    end

    ##
    # Sets the status message and progress if this instance has a lock on the status/lock file.
    #
    # Returns true after successfully setting the status.
    # Returns false if this instance does not currently hold the lock.
    #
    def set_status(message, percentage)
      return false unless have_lock?
      @stat_handle.rewind
      @stat_handle.truncate 0
      @stat_handle.write(message.to_s.strip + "\n")
      @stat_handle.write(percentage.to_s.strip + "\n")
      @stat_handle.flush
      true
    end

    ##
    # Releases the lock on the status/lock file if this instance holds the lock.
    #
    # Returns true.
    #
    def release_lock
      return true unless @lock_handle
      begin
        set_message ''
        @lock_handle.flock(File::LOCK_UN)
      ensure
        @stat_handle.close rescue nil
        @lock_handle.close rescue nil
        @stat_handle = @lock_handle = nil
      end

      true
    end

    ##
    # Acquires the lock on the status/lock file.
    #
    # Returns true on success or if this instance already holds the lock.
    # Returns false if another process holds the lock.
    #
    def acquire_lock
      return true if @lock_handle
      begin
        @lock_handle = File.open(lock_file_path, File::RDWR | File::CREAT)
        raise StandardError.new('Already locked') unless @lock_handle.flock(File::LOCK_EX | File::LOCK_NB)
        @lock_handle.rewind
        @lock_handle.truncate 0
        @stat_handle = File.open(status_file_path, File::RDWR | File::CREAT)
        raise StandardError.new('Failed to open status') unless @stat_handle
        @stat_handle.rewind
        @stat_handle.truncate 0
      rescue
        if @stat_handle
          @stat_handle.close rescue nil
        end
        if @lock_handle
          @lock_handle.flock(File::LOCK_UN) rescue nil
          @lock_handle.close rescue nil
        end
        @stat_handle = nil
        @lock_handle = nil
      end
      !!@lock_handle
    end

    ##
    # Determines if any process currently holds the lock on the status/lock file.
    #
    # Returns true if the file is locked, otherwise returns false.
    #
    def self.locked?
      global_instance.is_locked?
    end

    ##
    # Gets the current status from the status/lock file.
    #
    # See #get_status for a description of the returned hash.
    #
    def self.current
      global_instance.get_status
    end

    ##
    # Runs the provided block with a lock on the status/lock file.
    #
    # If a lock can be acquired, a GlobalStatus object is yielded to the block.
    # The lock will automatically be released when the block exits.
    #
    # If a lock cannot be acquire, then false is yielded to the block.
    # The block needs to test for this case to ensure that the appropriate
    # error handling is performed.
    #
    # The only time that the block is not called is if +raise_on_failure+ is set,
    # in which case an exception is raised instead of yielding to the block.
    #
    def self.lock_for(raise_on_failure = false, &block)
      return unless block_given?
      status = GlobalStatus.new
      if status.acquire_lock
        begin
          yield status
        ensure
          status.release_lock
        end
      else
        raise BarkestCore::GlobalStatus::FailureToLock.new if raise_on_failure
        yield false
      end
    end

    private

    def self.global_instance
      @global_instance ||= GlobalStatus.new
    end

  end
end
