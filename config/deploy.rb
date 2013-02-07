require "bundler/capistrano"

set :application, "hive"
set :repository,  "git://github.com/entropie/hive.git"

set :scm, :git

set :branch, "master"


BEEHIVES = Dir.glob("beehives/*").map { |b| File.basename(b) }

requested_beehive = ARGV.first

if requested_beehive and BEEHIVES.include?(requested_beehive)
  case requested_beehive
  when "klangwolke"
    role :web,      "dynamiet.nine.ch"
    role :app,      "dynamiet.nine.ch"
    role :db,       "dynamiet.nine.ch", :primary => true
  else
    role :web,      "pullies"
    role :app,      "pullies"
    role :db,       "pullies",          :primary => true
  end
end

set :deploy_via,                  :remote_cache
set :normalize_asset_timestamps,  false
set :git_enable_submodules,       false




BEEHIVES.each do |beehive|
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

      task :restart do
        run "touch #{File.join(current_path, "beehives", beehive.to_s, "tmp", "restart.txt")}"
      end

      task :default do
        transaction do
          update
          update_beehive
          restart
        end
      end

      task :setup do
        dirs = [deploy_to, releases_path, shared_path]
        run "mkdir -p #{dirs.join(' ')}"
        run "chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
      end
    end


    if beehive == :klangwolke
      #
      # UPLOADS
      #
      namespace :uploads do
        desc "Creates the upload folders unless they exist and sets the proper upload permissions."
        task :setup, :except => { :no_release => true } do
          dirs = uploads_dirs.map { |d| File.join(shared_path, d) }
          run "mkdir -p #{dirs.join(' ')} && chmod g+w #{dirs.join(' ')}"
        end

        desc "[internal] Creates the symlink to uploads shared folder for the most recently deployed version."
        task :symlink, :except => { :no_release => true } do
          run "rm -rf #{release_path}/beehives/klangwolke/media"
          run "ln -nfs #{shared_path}/media #{release_path}/beehives/#{beehive}/media"
        end

        desc "[internal] Computes uploads directory paths and registers them in Capistrano environment."
        task :register_dirs do
          set :uploads_dirs,    %w(media)
          set :shared_children, fetch(:shared_children) + fetch(:uploads_dirs)
        end

        after       "deploy:update_beehive", "uploads:symlink"
        on :start,  "uploads:register_dirs"
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
