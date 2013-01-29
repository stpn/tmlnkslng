require "bundler/capistrano"


# -*- encoding : utf-8 -*-

set :assets_dependencies, %w(app/assets lib/assets vendor/assets Gemfile.lock config/routes.rb)


set :application, "timelinksnlp"

set :repository, "git@github.com:stpn/tmlnkslng.git"
set :scm, :git
set :git_shallow_clone, 1
set :branch, "master"

set :location, "ec2-23-23-158-122.compute-1.amazonaws.com"

role :app , location
role :web , location
role :db , location, :primary => true



set :deploy_via, :remote_cache

set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") 

set :user, "ubuntu"
set :use_sudo, false
set :deploy_to, "/home/ubuntu/timelinksnlp"
ssh_options[:forward_agent] = true
default_run_options[:pty] = true
ssh_options[:keys] = ["#{ENV['HOME']}/.ec2/vidoai.pem"]

set :keep_releases, 1

# setup some Capistrano roles




#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"") 
set :rvm_type, :user


set :default_environment, { 
  'PATH' => "/home/ubuntu/.rvm/gems/ruby-1.9.3-p125/bin:/home/ubuntu/.rvm/gems/ruby-1.9.3-p125@global/bin:/home/ubuntu/.rvm/rubies/ruby-1.9.3-p125/bin:/home/ubuntu/.rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/lib/jvm/java-6-openjdk-amd64:$PATH",
  'JAVA_HOME' => "/usr/lib/jvm/java-6-openjdk-amd64",
  'PKG_CONFIG_PATH' => '$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig'

  # 'RUBY_VERSION' => 'ruby-1.9.3-p125'
  # 'GEM_HOME' => '/home/ubuntu/.rvm/gems/ree/1.8.7'
  # 'GEM_PATH' => '/home/ubuntu/.rvm/gems/ree/1.8.7' 
}


desc "show path" 
task :show_path do
  run "echo $PATH"
end



namespace :web_assets do 
desc "Copy resque-web assets into public folder"
task :copy_resque_assets do
  target = File.join(release_path,'public','resque')
  run "cp -r `cd #{current_path} && bundle show resque`/lib/resque/server/public #{target}"
end
end


namespace :resque do

  desc "Starts resque-pool daemon."
  task :start  do
    run "cd #{latest_release};bundle exec resque-pool -d -E #{rails_env} start"
    sudo "/etc/init.d/redis-server start"

  end

  desc "Sends INT to resque-pool daemon to close master, letting workers finish their jobs."
  task :stop  do
    pid = "#{latest_release}/tmp/pids/resque-pool.pid"
    sudo "kill -2 `cat #{pid}`"
    sudo "/etc/init.d/redis-server stop"
  end

  desc "List all resque processes."
  task :ps do
    run 'ps -ef f | grep -E "[r]esque-(pool|[0-9])"'
  end

  desc "List all resque pool processes."
  task :psm do
    run 'ps -ef f | grep -E "[r]esque-pool"'
  end


end


namespace :stanford do

  desc "Copy language assets"
  task :copy, :roles => :app  do
    puts ENV['GEM_HOME']
    run  "if [ ! -d /home/ubuntu/timelinksnlp/shared/bundle/ruby/1.9.1/gems/stanford-core-nlp-0.5.1/bin/grammar ]; then cd #{latest_release}/ && sh wgetunzip.sh https://s3.amazonaws.com/Vide_ai-dev/FullEngLatest.zip /home/ubuntu/timelinksnlp/shared/bundle/ruby/1.9.1/gems/stanford-core-nlp-0.5.1/bin/; fi"     
  end


  task :force_copy, :roles => :app do
    run "cd #{latest_release}/ && sh wgetunzip.sh https://s3.amazonaws.com/Vide_ai-dev/FullEngLatest.zip /home/ubuntu/timelinksnlp/shared/bundle/ruby/1.9.1/gems/stanford-core-nlp-0.5.1/bin/;"
  end
end


namespace :passenger do
  desc "Restart Application"
  task :restart do
#    run "sudo /etc/init.d/nginx restart"
    run "cd #{latest_release} && sh restart_production.sh"
  end
end


# namespace :deploy do
#   namespace :assets do

#     desc <<-DESC
#       Run the asset precompilation rake task. You can specify the full path \
#       to the rake executable by setting the rake variable. You can also \
#       specify additional environment variables to pass to rake via the \
#       asset_env variable. The defaults are:

#         set :rake,      "rake"
#         set :rails_env, "production"
#         set :asset_env, "RAILS_GROUPS=assets"
#         set :assets_dependencies, fetch(:assets_dependencies) + %w(config/locales/js)
#     DESC
#     task :precompile, :roles => :web, :except => { :no_release => true } do
#       from = source.next_revision(current_revision)
#       if capture("cd #{latest_release} && #{source.local.log(from)} #{assets_dependencies.join ' '} | wc -l").to_i > 0
#         run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
#       else
#         logger.info "Skipping asset pre-compilation because there were no asset changes"
#       end
#     end

#   end
# end


after :deploy, "web_assets:copy_resque_assets"
#after :deploy, "deploy:migrate"
#after :deploy, "stanford:copy"

  

