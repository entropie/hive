require File.join(File.dirname(__FILE__), "..", "lib", "hive.rb")
require "bundler/capistrano"

set :application, "hive"
set :repository,  "git://github.com/entropie/hive.git"

set :scm, :git

set :branch, "master"


BEEHIVES = Dir.glob("beehives/*").map { |b| File.basename(b) }

requested_beehive = ARGV.first

set :deploy_via,                  :remote_cache
set :normalize_asset_timestamps,  false
set :git_enable_submodules,       false

set :shared_children,             %w(public/system tmp/pids)

set :default_environment, {
  'PATH' => "/usr/local/bin:$PATH"
}


def remote_file_exists?(path)
  results = []

  invoke_command("if [ -e '#{path}' ]; then echo -n 'true'; fi") do |ch, stream, out|
    results << (out == 'true')
  end

  results.all?
end

BEEHIVES.each do |beehive|
  beehive = File.basename(beehive).to_sym

  next if beehive == :test
  task beehive do
    set :deploy_to,             "/u/apps/#{beehive}"
    set :beehive_scm_source,    "/home/mit/Source/beehives/#{beehive}"
    set :beehive_path,          File.join(current_path, "beehives", beehive.to_s)


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
          backup
        end
      end

      task :backup do
        if remote_file_exists?("#{current_path}/beehives/klangwolke/media")
          run "ls -a #{current_path}/beehives/klangwolke/media/"
          #puts bhive.media_path
          local_backup_path = File.expand_path("~/Backup/#{beehive}")

        else
          $stderr.puts "no media directory to backup. skipping."
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
        sudo "ln -nfs #{current_path}/beehives/#{beehive}/config/nginx.conf      /etc/nginx/sites-enabled/#{beehive}.conf"
        sudo "ln -nfs #{current_path}/beehives/#{beehive}/config/unicorn_init.sh /etc/init.d/unicorn_#{beehive}"
      end
      after "deploy:setup", "deploy:setup_config"

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

      # task :restart do
      #   run "touch #{File.join(current_path, "beehives", beehive.to_s, "tmp", "restart.txt")}"
      # end

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
          run "mkdir #{release_path}/beehives/klangwolke/media"
          run "ln -nfs /home/mogulcloud/music #{release_path}/beehives/klangwolke/media/music"
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

  task :tunnel do
    public_host_username = 'mit'
    public_host = "mc"
    public_port = 9001
    local_port = public_port

    puts "Starting tunnel #{public_host}:#{public_port} to 0.0.0.0:#{local_port}"
    exec "ssh -nNT -g -R *:#{public_port}:0.0.0.0:#{local_port} #{public_host_username}@#{public_host}"
  end
end

namespace :deploy do
  task :default do
    $stderr.puts "dont call deploy directly, use `cap <beehive> deploy' instead"
    exit 1
  end
end
