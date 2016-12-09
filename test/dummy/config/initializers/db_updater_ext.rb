BarkestCore::MsSqlDbUpdater.register(
    'fake',
    before_update: Proc.new do |db_conn,user|
      STDOUT.puts 'Before we update the fake DB.'
    end,
    after_update: Proc.new do |db_conn,user|
      STDOUT.puts 'After we update the fake DB.'
    end,
    extra_params: {
        extra_1: {
            name: 'something',
            type: 'string',   # field type
            value: 'Something Else'
        },
        extra_2: {
            name: 'are_you_sure',
            label: 'Are you sure?',
            type: 'boolean',
            value: '1'    # 0 or 1
        },
        extra_3: {
            name: 'some_password',
            type: 'password',
            value: 'abc123'
        },
        extra_4: {
            name: 'some_select',
            type: 'in:%w(alpha bravo charlie delta echo)',
            value: 'delta'
        }
    },
    source_paths: 'sql'
)
