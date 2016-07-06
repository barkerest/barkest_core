module BarkestCore
  ##
  # This class simply locates a temporary working directory for the application.
  #
  # By default we shoot for shared memory such as /run/shm or /dev/shm.  If those
  # fail, we look to /tmp.
  #
  class WorkPath

    ##
    # Gets the temporary working directory location for the application.
    #
    def self.location
      @location ||=
          begin
            %w(/run/shm /var/run/shm /dev/shm /tmp).each do |root|
              if Dir.exist?(root)
                @location = try_path(root)
                break if @location
              end
            end
            @location
          end
    end

    ##
    # Gets a path for a specific temporary file.
    #
    def self.path_for(filename)
      raise StandardError.new('Cannot determine location.') unless location
      location + '/' + filename
    end

    ##
    # Gets the path to the system status file.
    #
    # This file is used by long running processes to log their progress.
    #
    def self.system_status_file
      @system_status_file ||= path_for('system_status')
    end

    private

    def self.app_name
      @app_name ||=
          if Rails.application.respond_to?(:app_name)
            Rails.application.app_name.underscore
          else
            Rails.application.class.name.underscore
          end.gsub('/','-')
    end

    def self.try_path(path)
      path += '/barkest_' + app_name
      return nil unless (Dir.exist?(path) || Dir.mkdir(path))
      begin
        test_file = path + '/test.file'
        File.write(test_file, app_name)
        File.delete(test_file)
      rescue
        return nil
      end
      path
    end

  end
end
