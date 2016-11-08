class SystemConfig < ::BarkestCore::DbTable

  validates :key,
            presence: true,
            length: { maximum: 128 },
            uniqueness: { case_sensitive: false }

  before_save :downcase_key

  def value=(new_value)
    val = new_value.nil? ? nil : new_value.to_yaml
    write_attribute :value, val
  end

  def value
    val = read_attribute(:value).to_s
    return nil if val.empty?
    YAML.load val
  end

  def self.get(key_name)
    record = where(key: key_name.to_s.downcase).first
    record ? record.value : nil
  end

  def self.set(key_name, value)
    key_name = key_name.to_s.downcase
    record = find_or_initialize_by(key: key_name)
    record.value = value
    record.save
  end

  private

  def downcase_key
    key.downcase!
  end

end
