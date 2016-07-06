class LdapAccessGroup < ActiveRecord::Base

  belongs_to :group, class_name: 'AccessGroup'

  validates :group,
            presence: true

  validates :name,
            presence: true,
            length: { maximum: 200 },
            uniqueness: { case_sensitive: false }

end
