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

---
There are a few special layouts you can create to modify parts of the layout easily.  Create these files in your
__views/layouts__ folder to have them get used automatically.  Use the _ prefixed notation.   
ie: "_nav_logo.html.erb" for "nav_logo"

*   __nav_logo__ Defines the logo in the top left corner of the webpage.  This should be an image tag inside of
    a link tag.    
    ie: `<a href="..."><img src="..."></a>`
*   __footer_copyright__ Defines the copyright text presented in the footer.  This can be anything you want 
    it to be.
*   __menu_admin__ Defines the administration menu.  You probably won't need to do anything with this 
    particular menu, but just in case, it is one of the easily overridable views.  
    Menus would be `<li>...</li>` items.  The container `<ul>...</ul>` is defined in the parent view.
*   __menu_anon__ Defines the menu available to all users, aka: the anonymous menu.  If you want to
    provide menu options to everyone, you would want to place them here.  
    Menus would be `<li>...</li>` items.  The container `<ul>...</ul>` is defined in the parent view.
*   __menu_auth__ Defines the menu available to authenticated users.  The default is just a link to the
    users list.  Your app may not even desire that link.  This is the view that is most likely to be 
    adjusted on a per-project basis since it defines the menu for users.  
    Menus would be `<li>...</li>` items.  The container `<ul>...</ul>` is defined in the parent view.
   
---
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

---
A `SystemConfig` (not namespaced) class exists that can be used to store configuration data for various
services.  For instance, by default the LDAP and email configurations are stored within `SystemConfig`.

This is handled by the `system_config` controller since the `SystemConfig` class doesn't care what is 
getting stored.  It does however offer the lovely capability to encrypt the stored configuration.

```ruby
my_config = {
  :some_int => 1234,
  :some_string => 'hello world',
  :some_bool => true
}

# Save the hash to the database in plain text.
SystemConfig.set :some_config, my_config

# Save the hash to the database in encrypted format.
SystemConfig.set :some_config, my_config, true

# Read the hash from the database (decrypted automatically if needed).
my_config = SystemConfig.get(:some_config)
```

The encryption key used by `SystemConfig` comes from the __secrets.yml__ configuration file. If the
`encrypted_config_key` is specified, that value will be used, otherwise the `secret_key_base` value
will be used.  If the value for the encryption key is changed, any stored encrypted configurations 
will be lost.  The `SystemConfig` class will return __nil__ if the value does not exist or cannot be 
decrypted.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkerest/barkest_core.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) 2016 [Beau Barker](mailto:beau@barkerest.com)
