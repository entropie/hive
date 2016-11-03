require File.join(File.dirname(__FILE__), "..", "lib", "hive.rb")
require "bundler/capistrano"

set :application, "hive"
set :repository,  "git://github.com/entropie/hive.git"

set :scm, :git

set :branch, "master"


BEEHIVES = Dir.glob("beehives/*").map { |b| File.basename(b) }

requested_beehive = ARGV.first

set :deploy_via,                  :checkout
set :normalize_asset_timestamps,  false
set :git_enable_submodules,       false

set :shared_children,             %w(public/system tmp/pids)

set :default_environment, {
  'PATH' => "/usr/local/bin:$PATH"
}


def remote_file_exists?(full_path)
  'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
end

BEEHIVES.each do |beehive|
  beehive = File.basename(beehive).to_sym

  next if beehive == :test
  task beehive do

    set :deploy_to,             "/u/apps/#{beehive}"
    set :beehive_scm_source,    "/home/mit/Source/#{beehive}"
    set :beehive_path,          File.join(current_path, "beehives", beehive.to_s)

    set :local_backup_path,     "/mnt/backup"

    set :backup_command,        "rsync --progress -auz -L -e ssh mc:#{current_path}/beehives/#{beehive}/media #{local_backup_path}/#{beehive}"

    set :beehive_source_media_path, File.join(File.expand_path("~"), "Data/hive/media/#{beehive}-media")

    set :chown_cmd,             "chown mit:users "
    
    # get configuration variables from beehive
    bhive = Hive::Beehives.load(beehive)[beehive]
    bhive.assets.read

    # set roles from config variables
    if not (config_roles = bhive.config.roles).nil?
      [:web, :app, :db].each do |r|
        role r, config_roles[r]
      end
    end

    namespace :backup do

      task :default do
        transaction do
          backup_sql if bhive.config.database  # check wheater we use a db or not
          backup_media
        end
      end

      task :clean_remote_media do
        run "cd %s && git commit -am 'Update from cap backup:clean_remote_media'" % [bhive.media_path]
      end

      task :update_local_media do
        system "echo 'cd %s && git pull'" % beehive_source_media_path
      end

      task :default do
        transaction do
          clean_remote_media
          update_local_media
        end
      end

      # task :backup_sql do
      #   remote_file = "#{current_path}/beehives/#{beehive}/media/sql-backup"
      #   run "mkdir -p #{remote_file}"

      #   database, username = bhive.config.database[:database], bhive.config.database[:user]
      #   run "sudo -u postgres pg_dump --username=#{username} #{database} > #{remote_file}/#{Time.now.strftime("%Y-%m-%d")}.sql"
      # end

      # task :backup_media do
      #   remote_file = "#{current_path}/beehives/#{beehive}/media"
      #   if remote_file_exists?(remote_file)
      #     puts backup_command
      #     system backup_command
      #   else
      #     $stderr.puts "no media directory to backup. skipping."
      #   end
      # end
      #
      # task :mount_backup do
      #   system("sshfs mit@backup:/home/backup #{local_backup_path}")
      # end
      #
      # task :umount_backup do
      #   system("sudo umount #{local_backup_path}")
      # end
      # 
      # before "backup", "backup:mount_backup"
      # after "backup", "backup:umount_backup"

    end

    namespace :deploy do

      %w[start stop restart].each do |command|

        desc "#{command} unicorn server"
        task command, :roles => :app, :except => { :no_release => true } do
          run "/etc/init.d/unicorn_#{beehive} #{command}"
        end
      end

      task :setup_config, :roles => :app do
        sudo "ln -nfs #{current_path}/beehives/#{beehive}/config/nginx.conf      /etc/nginx/sites-enabled/#{beehive}.conf"
        sudo "ln -nfs #{current_path}/beehives/#{beehive}/config/unicorn_init.sh /etc/init.d/unicorn_#{beehive}"
      end

      task :link_media, :roles => :app do
        run "ln -s %s %s" % [bhive.media_path, beehive_source_media_path]
      end

      after "deploy:setup", "deploy:setup_config"
      after "deploy:setup", "deploy:link_media"

      task :update_beehive do
        run "rm -rf #{beehive_path}" # rm submodule path
        run "cd #{File.dirname(beehive_path)} && git clone #{beehive_scm_source} #{beehive}"
        run "cd #{beehive_path} && git pull origin master"
      end

      # task :restart do
      #   run "touch #{File.join(current_path, "beehives", beehive.to_s, "tmp", "restart.txt")}"
      # end
      task :link_media do
        live_media_path = File.join(beehive_path, "media")
        unless remote_file_exists?(live_media_path)
          "ln -s #{beehive_source_media_path} #{live_media_path}"
        end
      end

      # task :update do
      #   puts beehive_path
      # end

      task :default do
        transaction do
          update
          #update_beehive
          #link_media
          #restart
        end
      end

      task :setup do
        puts capture("if [ ! -d /u ]; then sudo mkdir /u && sudo #{chown_cmd} /u; else echo 2;fi")
        dirs = [deploy_to, releases_path, shared_path]
        run "mkdir -p #{dirs.join(' ')}"
        run "chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
        run "chown mit:users #{dirs.join(' ')}"
      end
    end

    # if beehive == :klangwolke
    #   #
    #   # UPLOADS
    #   #
    #   namespace :uploads do
    #     desc "Creates the upload folders unless they exist and sets the proper upload permissions."
    #     task :setup, :except => { :no_release => true } do
    #       dirs = uploads_dirs.map { |d| File.join(shared_path, d) }
    #       run "mkdir -p #{dirs.join(' ')} && chmod g+w #{dirs.join(' ')}"
    #     end

    #     desc "[internal] Creates the symlink to uploads shared folder for the most recently deployed version."
    #     task :symlink, :except => { :no_release => true } do
    #       run "rm -rf #{release_path}/beehives/klangwolke/media"
    #       run "mkdir #{release_path}/beehives/klangwolke/media"
    #       run "ln -nfs /home/mogulcloud/music #{release_path}/beehives/klangwolke/media/music"
    #     end

    #     desc "[internal] Computes uploads directory paths and registers them in Capistrano environment."
    #     task :register_dirs do
    #       set :uploads_dirs,    %w(media)
    #       set :shared_children, fetch(:shared_children) + fetch(:uploads_dirs)
    #     end

    #     after       "deploy:update_beehive", "uploads:symlink"
    #     on :start,  "uploads:register_dirs"
    #   end
    # end

  end

end

namespace :deploy do
  task :default do
    $stderr.puts "dont call deploy directly, use `cap <beehive> deploy' instead"
    exit 1
  end
end
