# GIT user settings
default[:olyn_git][:user][:git][:data_bag_item] = 'system_admin'

# Path to the main Git repos directory
default[:olyn_git][:repo][:dir] = "#{Chef::Config[:olyn_application_data_path]}/git-repos"

# Path to the Git build tracking directory
default[:olyn_git][:build][:dir] = "#{Chef::Config[:olyn_application_data_path]}/git-build"

# Command for running Composer after sync
default[:olyn_git][:build][:composer][:command] = 'composer install --no-dev'

# Command for running Berkshelf after sync
default[:olyn_git][:build][:berkshelf][:command] = "RUBYOPT='-W0' berks vendor cookbooks"
