class AccessGroupUserMember < ::BarkestCore::DbTable

  belongs_to :group, class_name: 'AccessGroup'
  belongs_to :member, class_name: 'User'

  validates :group_id, presence: true
  validates :member_id, presence: true, uniqueness: { scope: :group_id }

end
