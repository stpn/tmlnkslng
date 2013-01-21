require 'resque/tasks'


namespace :resque do
  desc "let resque workers always load the rails environment"
  task :setup => :environment do
  	  Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
  end

  desc "kill all workers (using -QUIT), god will take care of them"
  task :stop_workers => :environment do
    pids = Array.new

    Resque.workers.each do |worker|
      pids << worker.to_s.split(/:/).second
    end

    if pids.size > 0
      system("kill -QUIT #{pids.join(' ')}")
      Resque.workers.first.prune_dead_workers
    end

  end
end
