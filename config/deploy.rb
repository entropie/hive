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

def is_dev_machine?
  capture("hostname").strip == "xeno"
end

BEEHIVES.each do |beehive|
  beehive = File.basename(beehive).to_sym

  next if beehive == :test
  task beehive do

    set :deploy_to,             "/u/apps/#{beehive}"
    set :beehive_scm_source,    "/home/mit/Source/beehives/#{beehive}"
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

    namespace :web do
      task :start do
        run "cd %s && bundle exec unicorn -D -c %s -E production" % [current_path, File.join(beehive_path, "config/unicorn.rb")]
      end

      before "web:restart", "web:stop"
      task :restart do
      end
      after 'web:restart', 'web:start'

      task :stop do
        pidfile = "/home/unicorn/#{beehive}.pid"
        if remote_file_exists?(pidfile)
          pid = capture("cat #{pidfile}").strip
          run "kill #{pid}"
          run "rm %s" % pidfile
        end
      end

      before 'web:reset', "web:stop"
      task :reset do
        run "sudo killall nginx; sudo nginx"
      end
      after 'web:reset', "web:start"
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

    end

    namespace :deploy do

      %w[start stop restart].each do |command|

        desc "#{command} unicorn server"
        task command, :roles => :app, :except => { :no_release => true } do
          run "/etc/init.d/unicorn_#{beehive} #{command}"
        end
      end

      task :setup_config, :roles => :app do
        conf = "#{beehive}.conf"
        nginx_conf = "nginx.conf"
        hn = capture("hostname").strip

        if !is_dev_machine?
          conf, nginx_conf = "#{beehive}-#{hn}.conf", "nginx-#{hn}.conf"
        end
        
        sudo "ln -nfs #{current_path}/beehives/#{beehive}/config/#{nginx_conf}   /etc/nginx/sites-enabled/#{conf}"
        sudo "ln -nfs #{current_path}/beehives/#{beehive}/config/unicorn_init.sh /etc/init.d/unicorn_#{beehive}"
      end

      # task :link_media, :roles => :app do
      #   run "ln -s %s %s" % [bhive.media_path, beehive_source_media_path]
      # end
      after "deploy:setup", "deploy:setup_config"
      

      task :update_beehive do
        run "rm -rf #{beehive_path}" # rm submodule path
        run "cd #{File.dirname(beehive_path)} && git clone #{beehive_scm_source} #{beehive}"
        run "cd #{beehive_path} && git pull origin master"
        run "cd #{current_path} && bundle install"
      end
      after "deploy:update_beehive", "deploy:link_media"

      task :update_vendor do
        run "cd #{beehive_path} && git submodule update --init --recursive"
      end
      after 'deploy:link:_media', 'deploy:update_vendor'

      task :link_media do
        live_media_path = File.join(beehive_path, "media")
        unless remote_file_exists?(live_media_path)
          run "ln -s #{beehive_source_media_path} #{live_media_path}"
        end
      end

      task :default do
        transaction do
          update
          update_beehive
          link_media
        end
      end
      after 'deploy', 'web:reset'


      task :setup do
        %w'/u /home/unicorn'.each do |lpath|
          run "if [ ! -d %s ]; then sudo mkdir %s && sudo #{chown_cmd} %s; else echo;fi" % [lpath, lpath, lpath]
        end

        dirs = [deploy_to, releases_path, shared_path]

        run "mkdir -p #{dirs.join(' ')}"
        run "chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
        run "chown mit:users #{dirs.join(' ')}"
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
