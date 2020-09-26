# Create the build tracking folder
directory node[:olyn_git][:build][:dir] do
  mode 0755
  owner 'root'
  group 'root'
  recursive true
  action :create
end

# Load information about the current server from the servers data bag
server = data_bag_item('servers', node[:hostname])

# Loop through each repo item in the data bag
data_bag('git_repos').each do |repo_item|

  # Load the repo data bag item
  repo = data_bag_item('git_repos', repo_item)

  # Load the repo user data bag item
  repo_user = data_bag_item('system_users', repo[:worktree][:user_data_bag_item])

  # Set the default branch if the repo didn't specify one
  repo[:branch] = server[:options][:git][:default_branch] if repo[:branch].nil?

  # Define the build tracker file path
  build_tracker_file = "#{node[:olyn_git][:build][:dir]}/#{repo[:id]}.build"

  # If the repo needs to run Composer after a sync
  if repo[:build][:is_composer]

    # Run composer
    execute "composer_#{repo[:id]}" do
      command node[:olyn_git][:build][:composer][:command]
      cwd repo[:worktree][:path]
      user repo_user[:username]
      group repo_user[:groups]['primary']
      environment({ 'HOME' => "/home/#{repo_user[:username]}",
                    'USER' => repo_user[:username] })
      action :nothing
      subscribes :run, "file[git_build_tracker_#{repo[:id]}]", :delayed
    end

  # If the repo needs to run Berkshelf after a sync
  elsif repo[:build][:is_berkshelf]

    # Run Berkshelf
    execute "berkshelf_#{repo[:id]}" do
      command node[:olyn_git][:build][:berkshelf][:command]
      cwd repo[:worktree][:path]
      user repo_user[:username]
      group repo_user[:groups]['primary']
      environment({ 'HOME' => "/home/#{repo_user[:username]}",
                    'USER' => repo_user[:username] })
      action :nothing
      subscribes :run, "file[git_build_tracker_#{repo[:id]}]", :delayed
    end

  end

  # Define the build file tracker for this repo
  file "git_build_tracker_#{repo[:id]}" do
    path build_tracker_file
    mode 0750
    owner 'root'
    group 'root'
    action :create_if_missing
  end

end
