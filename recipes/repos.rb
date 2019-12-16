# Loop through each repo item in the data bag
data_bag('git_repos').each do |repo_item|

  # Load the repo data bag item
  repo = data_bag_item('git_repos', repo_item)

  # Load the repo user data bag item
  repo_user = data_bag_item('system_users', repo[:worktree][:user_data_bag_item])

  # Specify the base folder for this repo
  git_base = "#{node[:olyn_git][:repos_path]}#{repo[:id]}/"

  # Create the base repo folder
  directory git_base do
    mode 0755
    owner repo_user[:username]
    group repo_user[:groups]['primary']
    recursive true
    action :create
  end

  # Create the worktree folder
  directory repo[:worktree][:path] do
    mode repo[:worktree][:mode]
    owner repo_user[:username]
    group repo_user[:groups]['primary']
    recursive true
    action :create
  end

  # Initialize the Git repo
  execute "git_init_#{repo[:id]}" do
    command "git init --separate-git-dir=\"#{git_base}\""
    cwd repo[:worktree][:path]
    user repo_user[:username]
    group repo_user[:groups]['primary']
    action :run
    creates "#{repo[:worktree][:path]}.git"
  end

end