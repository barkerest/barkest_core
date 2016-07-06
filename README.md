# BarkestCore

The BarkestCore project gets a web application off to a quick start by building on the Rails 4 framework.

This project includes basic user management, group based authorization, and a number of helper methods.

Most Barker EST web applications use this gem for authentication, authorization, and helper routines.
There are customizations added to controllers, models, and test cases.  There is also a customization added
to the configuration system that ensures a database configuration exists for test and development environments.
This allows you to leave the YAML files out of your git repository without having to worry about the out-of-box
experience that this would normally cause issues with.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'barkest_core'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barkest_core

Once installed, you will want to configure the gem:

    $ bundle exec rails generate barkest_core:install

The configuration will go through everything that BarkestCore needs to function, but will also
offer to provide you with some reasonable defaults and protections (removing YAML config files from repo).
Only certain parts are required for BarkestCore to function.


## Usage

This gem provides the foundation for a Rails application.  It is somewhat mean in that it is not fully namespaced.  It
uses the `User` model for, well, users, and the `AccessGroup` model for user-group memberships.  This would be important
to keep in mind when developing your application.  For Barker EST applications, this happens to be exactly what I want,
so there was no need to support namespacing these models or controllers.

During configuration, BarkestCore offers to update your `ApplicationController` class and your application layout files.
If you opted to let BarkestCore perform these updates, then your application should be ready to go.  If not, then there
may be some issues.  To truly take advantage of BarkestCore, you should have your `ApplicationController` inherit from
`::BarkestCore::ApplicationControllerBase`.  This gives you all the session and user based helper functionality as well
as the `authorize!` method inside your controllers.  The layouts are less important, BarkestCore provides some generic
layouts as default, but you can easily use your own layouts.

Utility models are namespaced.  These include the `UserManager` (which you shouldn't need to use directly), `WorkPath`,
`GlobalStatus`, and `PdfTableBuilder` classes, among others.

The `WorkPath` class gives you a simple way to work with
an application specific temporary directory.  It looks for shared memory locations before defaulting to "/tmp" so on
systems that have shared memory ("/dev/shm") the temporary files will be stored there.

```ruby
my_temp_file = BarkestCore::WorkPath.path_for('some.file')
```

The `GlobalStatus` class allows you to "lock" the system in one process/thread and provide status updates to another
process/thread.  This is useful if you have long running processes.  In one session you can use the `GlobalStatus` class
to lock the system to perform the work.  In another you can monitor the status to determine when the other session has
finished.

```ruby
BarkestCore::GlobalStatus.lock_for do
  # do some long running code here...
end
```




## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkerest/barkest_core.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) 2016 [Beau Barker](mailto:beau@barkerest.com)
