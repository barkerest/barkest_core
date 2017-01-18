##
# This class initializes the seeds for the database.
# To seed your database tables, create files in the db/seeds directory.
#
# Make sure the seeds can be reseeded safely.
# ie - After a migration we may want to add more seeded data, but previously seeded data should
# not be reprocessed.
#
# Seed files should be named as such #{library}_#{index}_#{desc} where #{index} is a number that
# can be sorted to ensure the order is processed correctly.  For instance, you would want to use
# a 2-digit number ('00' => '99') if you have more than 10 seed files to process.
#   "barkest_core_01_create_users"  => { :library => 'barkest_core', :index => 1, :desc => 'create users' }
#
class Seeds
  # :nodoc:
  def self.process
    list = []
    BarkestCore.send(:db_seed_path_registry) { |path| list += Dir.glob(path) }
    list.sort do |a,b|
      a = File.basename(a)
      b = File.basename(b)
      a_core = (a.index('barkest_core') == 0)
      b_core = (b.index('barkest_core') == 0)
      if a_core && b_core
        a <=> b
      elsif a_core
        -1
      elsif b_core
        1
      else
        a <=> b
      end
    end.each do |seed_file|
      file_name = File.basename(seed_file)[0...-3]
      data = /^(?<library>[^\d_][^_]*(_[^\d_][^_]*)*)_(?<index>\d+)_(?<desc>.*)$/.match(file_name)
      label_prefix = '== ' +
          if data
            data['library'].camelcase + ' (' + data['desc'].humanize + ')'
          else
            file_name.camelcase
          end
      label = label_prefix + ': seeding '
      puts label + ('=' * (79 - label.length))
      start_time = Time.now
      require seed_file
      elapsed_time = Time.now - start_time
      label = label_prefix + sprintf(': seeded (%0.4fs) ', elapsed_time)
      puts label + ('=' * (79 - label.length))
    end
  end
end

Seeds.process