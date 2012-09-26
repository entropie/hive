require "bundler/capistrano"

set :application, "hive"
set :repository,  "git://github.com/entropie/hive.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :branch, "master"

role :web, "pullies"
role :app, "pullies"
role :db,  "pullies", :primary => true

set :deploy_via, :remote_cache

set :normalize_asset_timestamps, false

set :git_enable_submodules, true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end


namespace :deploy do
  task :default do
    #beehive = ENV['BEEHIVE']

    #abort"no beehive given, use BEEHIVE=foo cap deploy"
    update
  end
end
