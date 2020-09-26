# Include the main git recipe
include_recipe 'olyn_git::git'

# Check to make sure there are repos to add/sync
repos =
  begin
    data_bag('git_repos')
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
    nil
  end

# Configure and init repos
include_recipe 'olyn_git::repos' if repos

# Sync and checkout repos
include_recipe 'olyn_git::sync' if repos

# Build Composer and Berkshelf dependencies
include_recipe 'olyn_git::build' if repos
