# config valid only for current version of Capistrano
lock '3.7.2'

set :application, 'sinatratex'
set :repo_url, 'git@github.com:jules2689/sinatratex.git'

unicorn_conf = "unicorn.rb"
env = 'production'
namespace :deploy do
  task :restart do
    on roles(:app) do
      execute "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{env} -D; fi"
    end
  end
  task :start do
    on roles(:app) do
      execute "cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{env} -D"
    end
  end
  task :stop do
    on roles(:app) do
      execute "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
    end
  end
end
