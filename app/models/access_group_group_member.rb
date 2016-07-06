class AccessGroupGroupMember < ::BarkestCore::DbTable
  belongs_to :group, class_name: 'AccessGroup'
  belongs_to :member, class_name: 'AccessGroup'

  validates :group_id, presence: true
  validates :member_id, presence: true, uniqueness: { scope: :group_id }

  # member_id should not equal group_id or cause infinite recursion.
  # these two issues are addressed in the AccessGroup model.

end
