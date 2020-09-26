# Load information about the current server from the servers data bag
server = data_bag_item('servers', node[:hostname])

# Loop through each repo item in the data bag
data_bag('git_repos').each do |repo_item|

  # Load the repo data bag item
  repo = data_bag_item('git_repos', repo_item)

  # Load the repo user data bag item
  repo_user = data_bag_item('system_users', repo[:worktree][:user_data_bag_item])

  # Specify the base folder for this repo
  git_base = "#{node[:olyn_git][:repo][:dir]}/#{repo[:id]}/"

  # Set the default branch if the repo didn't specify one
  repo[:branch] = server[:options][:git][:default_branch] if repo[:branch].nil?

  # Sync the git repo
  git "sync_#{repo[:id]}" do
    repository repo[:remote][:url]
    destination repo[:worktree][:path]
    revision repo[:branch]
    checkout_branch repo[:branch]
    enable_checkout false
    environment(GIT_DIR: git_base, GIT_WORK_TREE: repo[:worktree][:path])
    user repo_user[:username]
    group repo_user[:groups]['primary']
    ssh_wrapper "/home/#{repo_user[:username]}/.ssh/ssh_wrapper.sh"
    action :sync
    only_if { repo[:remote][:sync] && repo_user[:options]['ssh']['enabled'] && repo_user[:options]['ssh']['wrapper']['enabled'] }
    notifies :run, "bash[git_base_owner_#{repo[:id]}]", :before
    notifies :run, "bash[git_clean_#{repo[:id]}]", :immediately
    notifies :delete, "file[git_build_tracker_#{repo[:id]}]", :immediately
  end

  # Set the permissions for the entire worktree
  bash "git_base_owner_#{repo[:id]}" do
    code <<-ENDOFCODE
      # Chown the entire base folder
      chown -R #{repo_user[:username]} #{repo[:worktree][:path]}
      chgrp -R #{repo_user[:groups]['primary']} #{repo[:worktree][:path]}
    ENDOFCODE
    action :nothing
  end

  # Force a checkout and clean
  bash "git_clean_#{repo[:id]}" do
    code <<-ENDOFCODE
      WORKTREE=#{repo[:worktree][:path]}
      GITDIR=#{git_base}

      cd $WORKTREE
      # update the working tree
      git --work-tree=./ --git-dir=$GITDIR checkout -f #{repo[:branch]}
      git --work-tree=./ --git-dir=$GITDIR clean -fd
      # return to git directory
      cd $GITDIR
    ENDOFCODE
    user repo_user[:username]
    group repo_user[:groups]['primary']
    action :nothing
  end

  # Loop through each realm in the worktree
  repo[:worktree][:realms].each do |realm|

    # Specify the full realm path
    realm_base = "#{repo[:worktree][:path]}/#{realm[:path]}"

    # Determine the owner
    realm[:user]  = realm[:root_owned] ? 'root' : repo_user[:username]
    realm[:group] = realm[:root_owned] ? 'root' : repo_user[:groups]['primary']

    # Create the base folder for the realm
    directory realm_base do
      mode realm[:modes][:directories]
      owner realm[:user]
      group realm[:group]
      recursive true
      action :create
    end

    # Set the permissions for this repo
    bash "git_realm_permissions_#{realm[:name]}" do
      code <<-ENDOFCODE
      # Chown the entire realm folder
      chown -R #{realm[:user]} #{realm_base}
      chgrp -R #{realm[:group]} #{realm_base}
      # Directory and file permissions
      find #{realm_base} -type d -exec chmod #{realm[:modes][:directories]} {} +
      find #{realm_base} -type f -exec chmod #{realm[:modes][:files]} {} +
      ENDOFCODE
      action :nothing
      subscribes :run, "directory[#{realm_base}]", :immediately
      subscribes :run, "bash[git_clean_#{repo[:id]}]", :immediately
    end

  end

end
