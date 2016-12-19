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

---
Because I generally have a need to interface with MS SQL for reporting purposes, I decided to build the
necessary models as well.  The models would be `MsSqlDbDefinition`, `MsSqlDefinition`, and `MsSqlFunction`.
---
The `MsSqlFunction` model basically allows you to use the output from a user-defined function in SQL to 
populate an ActiveRecord-like model.  These are read-only models, which fits in nicely with the output
from a user-defined function.  There are 3 steps to using the `MsSqlFunction`.
 1. Inherit from `BarkestCore::MsSqlFunction`.
 2. Tell it what connection to use.
 3. Tell it the name of the user-defined function.

```sql
CREATE FUNCTION [my_function] (
  @alpha INTEGER,
  @bravo VARCHAR(100),
  @charlie DATETIME
) RETURNS TABLE AS RETURN
SELECT
  LEN(ISNULL(@bravo,'')) AS [bravo_len],
  LEN(ISNULL(@bravo,'')) * ISNULL(@alpha,0) AS [alpha_bravo],
  CONVERT(FLOAT, LEN(ISNULL(@bravo, ''))) / 100.0 AS [bravo_len_pct],
  CONVERT(BIT, CASE
    WHEN @alpha > 25 THEN 1
    ELSE 0
  END) AS [alpha_gt_25],
  ISNULL(@alpha,0) AS [alpha],
  ISNULL(@bravo,'') AS [bravo],
  ISNULL(@charlie, GETDATE()) AS [charlie]
```

```ruby
class MyFunction < BarkestCore::MsSqlFunction
  use_connection 'ActiveRecord::Base'
  self.function_name = 'my_function'
end
```

Setting the function name causes the model to be built.  The name cannot be changed once set.
After the model has been built, you can view the parameters, set their default values, view the columns, 
and select from the function.

```ruby
MyFunction.parameters.inspect
# "{ :alpha=>{ :type=>:integer, :data_type=>'integer' ... }, ... }"

# Set some default parameter values.
MyFunction.parameters = { :alpha => 10, :bravo => 'yes' }

# The output from .parameters can be fed back into .parameters=, just set the :default keys.
p = MyFunction.parameters
p[:alpha][:default] = 10
p[:bravo][:default] = 'yes'
MyFunction.parameters = p

MyFunction.columns.inspect
# "{ { :name=>'bravo_len', :key=>:bravo_len, :data_type=>'int', :type=>:integer ...}, ...}"

results = MyFunction.select( :alpha => 25, :bravo => 'Hello', :charlie => 5.days.ago )
```

---
The `MsSqlDefinition` model is used primarily to load table, view, function, and procedure definitions
for the `MsSqlDbDefinition` model.  If the source used to create the `MsSqlDefinition` model was for a 
function, then the model will attempt to figure out the return value.  But other than that, it doesn't
try to figure out what you're trying to do with the code.

The `MsSqlDbDefinition` model is the model more likely to be used directly.  And the easiest way to use this
model is to use the `MsSqlDbDefinition.register` method.

```ruby
updater = MsSqlDbDefinition.register(
    :my_db,
    :source_paths => [ 'sql/my_db' ],
    :extra_params => {
        :extra_1 => {
            :name => 'some_connection_param',
            :label => 'Enter a value for some connection param',
            :type => 'text',
            :value => 'my default'
        }
    },
    :before_update => Proc.new do |db_conn, user|
      ...
    end,
    :after_update => Proc.new do |db_conn, user|
      ...
    end
)
```

Only the first parameter is required, that would be the database name.  The `source_paths` key would 
define the paths to search for SQL files when the updater is created.  You can add more sources later
using `add_source`, `add_source_definition`, and `add_source_path`.

```ruby
# Add one source to the updater.
# The first param is a timestamp in the YYYYMMDDHHMM format.
updater.add_source 201612121400, "CREATE VIEW [my_view] AS SELECT ..."

# The definition can be created in any valid manner, this option allows for maximum
# flexibility since you can tweak the actual definition going into the updater.
# The third param is the timestamp here.
my_def = MsSqlDefinition.new "CREATE VIEW [my_view] AS SELECT ...", nil, 201612121400
updater.add_source_definition my_def

# Just like in the constructor, search for all SQL files in the specified path.
# Neither the `source_paths` constructor key not this method are recursive.
# You need to add subdirectories individually.
updater.add_source_path "sql/my_db"
```

The `extra_params` key allows you to specify up to 5 extra configuration parameters for this database's 
connection.  Each extra param must have a name and type.  The label and value are optional, but recommended.

The `type` could be "text", "password", "integer", "float", "boolean", or the special "in:" type.  The "in:"
type allows you to specify a range of valid options for the parameter.

```ruby
    { :type => "in:MyCustomModel::VALID_EXTRA_PARAM_OPTIONS" }
```

The text after the "in:" will be evaluated and should return an enumerable object.

The `before_update` and `after_update` callbacks are executed repectively before or after the update
is performed.  The `db_conn` param is the current connection adapter.  The `user` param is the user executing
the update.  The `before_update` and `after_update` callbacks can also reference a method defined elsewhere.

```ruby
    { :before_update => "MyCustomModel.before_db_update(db_conn, user)" }
```

The `MsSqlDbDefinition.register` method registers the database configuration with the system so that the 
SystemConfigController can configure it, and also so that once it is configured the boot code can perform
the update.

It would be horrible to perform the update every time the app was started, which is where the timestamps
come into play.  The system generates a unique version for each source file based on the timestamp and the
CRC32 of the source contents.  The timestamps have a 1 minute resolution, and the CRC32 ensures the contents
haven't changed.  The timestamps are the real determiner for whether the object needs updated or not.  The
CRC32 would be just a quick check that everything is good.

When using the source paths, the modified time for the files is used for the timestamps.  When adding the
definition directly, you are providing the timestamp.

Once an object is created, the unique version is stored for the object.  The next time the update runs, it 
checks the stored version against the computed versions and only updates the objects it decides need to be
updated.




## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkerest/barkest_core.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright (c) 2016 [Beau Barker](mailto:beau@barkerest.com)
