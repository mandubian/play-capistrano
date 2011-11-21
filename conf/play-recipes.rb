#  Copyright 2011 Pascal Voitot [@mandubian][pascal.voitot.dev@gmail.com]
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at:
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

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

# without this, there are problems with sudo on remote server
default_run_options[:pty] = true

namespace :deploy do
  task :start do
    run "rm -f #{app_pid}; cd #{app_path}; chmod u+x run.sh; PLAY_PATH=#{play_path} PLAY_CMD=start nohup ./run.sh -Xss2048k --deps --pid_file=#{app_pid} --%prod 2>&1 >/dev/null" 
  end

  task :restart do
    stop
    start
  end

  task :stop do
    run "cd #{app_path}; PLAY_PATH=#{play_path} PLAY_PID=#{app_pid} PLAY_APP=#{app_path} . ./stop.sh"
  end
end

namespace :play do
  desc "view play pid"
  task :pid do
    run "cd #{app_path}; #{play_path}/play pid --pid_file=#{app_pid}"
  end

  desc "view play status"
  task :status do
    run "cd #{app_path}; #{play_path}/play status --pid_file=#{app_pid}"
  end	

  desc "view play version"
  task :version do
    run "cd #{app_path}; #{play_path}/play version --pid_file=#{app_pid}"
  end	

  desc "view running play apps"
  task :ps do
    run "ps -eaf | grep 'play'"
  end

  desc "kill play processes"
  task :kill do
    run "ps -ef | grep 'play' | grep -v 'grep' | awk '{print $2}'| xargs -i kill {} ; echo ''"
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
