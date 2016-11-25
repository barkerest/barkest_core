##
# Defines the authorization mechanism for the system.
#
# Access Groups can contain users and other access groups.  Any member gains access to
# any resource that allows the parent access group.
class AccessGroup < ::BarkestCore::DbTable

  include BarkestCore::NamedModel

  # hide the Groups<=>Users relationship association
  has_many :access_group_user_members, class_name: 'AccessGroupUserMember', foreign_key: 'group_id', dependent: :delete_all
  private :access_group_user_members, :access_group_user_members=

  # and expose the Users relationship instead.
  has_many :users, class_name: 'User', through: :access_group_user_members, source: :member

  # hide the Groups<=>Groups relationship association
  has_many :access_group_group_members, class_name: 'AccessGroupGroupMember', foreign_key: 'group_id', dependent: :delete_all
  private :access_group_group_members, :access_group_group_members=

  # and expose the group members.
  has_many :members, class_name: 'AccessGroup', through: :access_group_group_members, source: :member

  ##
  # Gets a list of memberships for this group.  (Read-only)
  def memberships(refresh = false)
    @memberships = nil if refresh
    @memberships ||= AccessGroupGroupMember.where(member_id: id).includes(:group).map{|v| v.group}.to_a.freeze
  end

  has_many :ldap_groups, class_name: 'LdapAccessGroup', foreign_key: 'group_id', dependent: :delete_all

  validates :name,
            presence: true,
            length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

  scope :sorted, ->{ order(:name) }

  ##
  # Gets the LDAP group list as a newline separated string.
  #
  # Specify +refresh+ to force the list to be reloaded.
  #
  # Specify a +separator+ if your would like to use something other than a newline.
  def ldap_group_list(refresh = false, separator = "\n")
    @ldap_group_list = nil if refresh
    @ldap_group_list ||= ldap_groups(refresh).map{|v| v.name.upcase}.join(separator)
  end

  ##
  # Splits a newline separated string into LDAP groups for this group.
  #
  # +value+ can be either a newline separated string or an array of strings.
  def ldap_group_list=(value)
    # convert string into array.
    value = value.split("\n") if value.is_a?(String)

    @ldap_group_list = nil

    if value.is_a?(Array) && value.count > 0

      value = value.map{|v| v.to_s.upcase}.uniq

      # remove those missing from the new list.
      ldap_groups.where.not(name: value).delete_all

      # remove items already existing in the current list.
      value.delete_if {|v| ldap_groups.where(name: v).count != 0 }

      # add items missing from the current list.
      value.each do |new_group|
        ldap_groups << LdapAccessGroup.new(group: self, name: new_group)
      end

    else

      # clear the list.
      ldap_groups.delete_all
    end

    ldap_groups true
  end

  ##
  # Determines if this group belongs to the specified group.
  def belongs_to?(group)
    group = AccessGroup.get(group) unless group.is_a?(AccessGroup)
    return false unless group
    safe_belongs_to?(group)
  end

  ##
  # Gets a list of all the groups this group provides effective membership to.
  def effective_groups
    ret = [ self ]
    memberships.each do |m|
      unless ret.include?(m)  # prevent infinite recursion
        tmp = m.effective_groups
        tmp.each do |g|
          ret << g unless ret.include?(g)
        end
      end
    end
    ret
  end

  protected

  def safe_belongs_to?(group, already_tried = [])
    return true if self == group
    already_tried << self
    memberships.each do |parent|
      unless already_tried.include?(parent)
        return true if parent.safe_belongs_to?(group, already_tried)
      end
    end
    false
  end

end
