module BarkestCore
  class ContactMessageTest < ActiveSupport::TestCase

    def setup
      @item = BarkestCore::ContactMessage.new(
          your_name: 'John Doe',
          your_email: 'jdoe@example.com',
          related_to: 'Nothing Important',
          body: 'This is my message.',
      )
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require subject for other' do
      # if related_to == 'other' then subject should now be required.
      @item.related_to = 'Other'
      assert_not @item.valid?
      @item.subject = 'Nothing Important'
      assert @item.valid?
      assert_required @item, :subject
    end

    test 'should require your_name' do
      assert_required @item, :your_name
    end

    test 'should require your_email' do
      assert_required @item, :your_email
    end

    test 'should require related_to' do
      assert_required @item, :related_to
    end

    test 'should require body' do
      assert_required @item, :body
    end

    test 'email validation should accept valid addresses' do
      valid = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@bax.cn]

      valid.each do |address|
        @item.your_email = address
        assert @item.valid?, "#{address.inspect} should be valid"
      end
    end

    test 'email validation should reject invalid addresses' do
      invalid = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com @example.com user@ user user@..com user@example..com]
      invalid.each do |address|
        @item.your_email = address
        assert_not @item.valid?, "#{address.inspect} should be invalid"
      end
    end


  end
end