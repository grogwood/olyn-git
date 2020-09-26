# Install Git
package 'git' do
  action :install
end

# Load the git user data bag item
git_user = data_bag_item('system_users', node[:olyn_git][:user][:git][:data_bag_item])

# Configure the package
template '/etc/gitconfig' do
  source 'gitconfig.erb'
  mode 0644
  owner 'root'
  group 'root'
  variables(
    username: git_user[:name],
    email:    git_user[:email]
  )
end

# Create the base repos folder
directory node[:olyn_git][:repo][:dir] do
  mode 0755
  owner 'root'
  group 'root'
  recursive true
  action :create
end
