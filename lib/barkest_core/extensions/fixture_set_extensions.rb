require 'active_record/fixtures'

# Add a few enhancements to FixtureSet that provide a method to define load and purge orders.
ActiveRecord::FixtureSet.class_eval do

  class << self
    alias :barkest_core_original_create_fixtures :create_fixtures
  end

  ##
  # Determines the fixtures that will be loaded first.
  #
  # Arguments can either be just table names or a hash of table names with indexes.
  # If just table names, then the tables are inserted at the end of the list.
  # If a hash, then the value is the index you want the table to appear in the load list.
  #
  # BarkestCore tables are pre-indexed to load before any other tables.
  #
  # Usage:
  #   ActiveRecord::FixtureSet.load_first :table_1, :table_2
  #   ActiveRecord::FixtureSet.load_first :table_1 => 0, :table_2 => 1
  def self.load_first(*args)
    priority_list = %w(access_groups users)

    @load_first ||= priority_list

    unless args.blank?
      args.each do |arg|
        if arg.is_a?(Hash)
          arg.each do |fix,order|
            fix = fix.to_s
            order += priority_list.length
            if order >= @load_first.length
              @load_first << fix unless @load_first.include?(fix)
            else
              @load_first.insert(order, fix) unless @load_first.include?(fix)
            end
          end
        else
          fix = arg.to_s
          @load_first << fix unless @load_first.include?(fix)
        end
      end
    end

    @load_first
  end

  ##
  # Determines the fixtures that will purged first.
  #
  # Arguments can either be just table names or a hash of table names with indexes.
  # If just table names then the tables are inserted at the beginning of the list.
  # If a hash, then the value is the index you want the table to appear in the purge list.
  #
  # BarkestCore tables are pre-indexed to be purged after any other tables added to this list.
  #
  # Usage:
  #   ActiveRecord::FixtureSet.purge_first :table_1, :table_2
  #   ActiveRecord::FixtureSet.purge_first :table_1 => 0, :table_2 => 1
  def self.purge_first(*args)
    priority_list = %w(ldap_access_groups access_group_user_members access_group_group_members user_login_histories users access_groups)

    @purge_first ||= priority_list

    unless args.blank?
      args.reverse.each do |arg|
        if arg.is_a?(Hash)
          arg.each do |fix,order|
            fix = fix.to_s
            if order <= 0
              @purge_first.insert(0, fix) unless @purge_first.include?(fix)
            elsif order >= @purge_first.length - priority_list.length
              @purge_first.insert(@purge_first.length - priority_list.length, fix) unless @purge_first.include?(fix)
            else
              @purge_first.insert(order, fix) unless @purge_first.include?(fix)
            end
          end
        else
          fix = arg.to_s
          @purge_first.insert(0, fix) unless @purge_first.include?(fix)
        end
      end
    end

    @purge_first
  end

  # :nodoc:
  def self.create_fixtures(fixtures_dir, fixture_set_names, *args)

    # delete all fixtures that have been added to purge_first
    purge_first.each do |fix|
      fix = const_get(fix.singularize.camelcase)
      if fix && fix.respond_to?(:delete_all)
        fix.delete_all
      end
    end

    reset_cache

    # if we are adding any of the prioritized fixtures, make them go first, followed by any other fixtures.
    fixture_set_names = load_first & fixture_set_names | fixture_set_names

    barkest_core_original_create_fixtures fixtures_dir, fixture_set_names, *args
  end
end
