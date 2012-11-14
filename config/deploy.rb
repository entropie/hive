require "bundler/capistrano"

set :application, "hive"
set :repository,  "git://github.com/entropie/hive.git"

set :scm, :git

set :branch, "master"

role :web, "pullies"
role :app, "pullies"
role :db,  "pullies", :primary => true

set :deploy_via,                  :remote_cache
set :normalize_asset_timestamps,  false
set :git_enable_submodules,       false

Dir.glob("beehives/*").each do |beehive|
  beehive = File.basename(beehive).to_sym

  next if beehive == :test
  task beehive do

    set :deploy_to,             "/u/apps/#{beehive}"
    set :beehive_scm_source,    "/home/mit/Source/beehives/#{beehive}"
    set :beehive_path,          File.join(current_path, "beehives", beehive.to_s)

    namespace :deploy do

      task :sync_beehive do
        cd_to = "cd #{beehive_path} && "
        run "#{cd_to} git branch web"
        run "#{cd_to} git checkout web"
        run "#{cd_to} git add ."
        run "#{cd_to} git commit -am 'update from web'"
        run "#{cd_to} git push origin web:master"
      end

      task :update_beehive do
        run "rm -rf #{beehive_path}" # rm submodule path
        run "cd #{File.dirname(beehive_path)} && git clone #{beehive_scm_source} #{beehive}"
        run "cd #{beehive_path} && git pull origin master"
      end

      task :default do
        transaction do
          update
          update_beehive
        end
      end

      task :setup do
        dirs = [deploy_to, releases_path, shared_path]
        run "mkdir -p #{dirs.join(' ')}"
        run "chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
      end
    end

  end
end

namespace :deploy do
  task :default do
    $stderr.puts "dont call deploy directly, use `cap <beehive> deploy' instead"
    exit 1
  end
end
