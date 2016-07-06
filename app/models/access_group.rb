class AccessGroup < ::BarkestCore::DbTable

  include BarkestCore::NamedModel

  # hide the Groups<=>Users relationship association
  has_many :access_group_user_members, class_name: 'AccessGroupUserMember', foreign_key: 'group_id'
  private :access_group_user_members, :access_group_user_members=

  # and expose the Users relationship instead.
  has_many :users, class_name: 'User', through: :access_group_user_members, source: :member

  # hide the Groups<=>Groups relationship association
  has_many :access_group_group_members, class_name: 'AccessGroupGroupMember', foreign_key: 'group_id'
  private :access_group_group_members, :access_group_group_members=

  # and expose the group members.
  has_many :members, class_name: 'AccessGroup', through: :access_group_group_members, source: :member

  ##
  # Gets a list of memberships for this group.  (Read-only)
  def memberships(refresh = false)
    @memberships = nil if refresh
    @memberships ||= AccessGroupGroupMember.where(member_id: id).includes(:group).map{|v| v.group}.to_a.freeze
  end

  has_many :ldap_groups, class_name: 'LdapAccessGroup', foreign_key: 'group_id'

  validates :name,
            presence: true,
            length: { maximum: 100 },
            uniqueness: { case_sensitive: false }

  scope :sorted, ->{ order(:name) }

  ##
  # Gets the LDAP group list as a newline separated string.
  def ldap_group_list
    ldap_groups.map{|v| v.name}.join("\n")
  end

  ##
  # Splits a newline separated string into LDAP groups for this group.
  def ldap_group_list=(value)
    new_list = []
    value.split("\n").each do |ldap_group|
      new_val = LdapAccessGroup.find_or_create_by(group: self, name: ldap_group.upcase)
      new_list << new_val unless new_list.include?(new_val)
    end
    ldap_groups = new_list
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
