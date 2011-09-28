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
  task :start do
    run "rm -f #{app_pid}; cd #{app_path}; PLAY_PATH=#{play_path} PLAY_CMD=start nohup ./run.sh -Xss2048k --deps --pid_file=#{app_pid} --%prod 2>&1 >/dev/null" 
  end

  task :restart do
    stop
    start
  end

  task :stop do
    run "#{play_path}/play stop #{app_path} --pid_file=#{app_pid}"
  end
end

namespace :play do
  desc "view running play apps"
  task :viewprocess do
    run "#{sudo} ps -ef | grep 'play/framework'"
  end

  desc "kill play processes"
  task :kill do
    run "#{sudo} ps -ef | grep 'play/framework' | grep -v 'grep' | awk '{print $2}'| xargs -i kill {} ; echo ''"
  end

  desc "view logfiles"
  task :logs, :roles => :app do
    run "tail -f #{shared_path}/log/#{application}.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

end
