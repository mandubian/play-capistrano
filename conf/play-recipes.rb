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
    play.start
  end

  task :restart do
    play.restart
  end

  task :stop do
    play.stop
  end
end

namespace :play do
  _cset :play_version, '1.2.4'
  _cset :play_zip_url do
    "http://download.playframework.org/releases/#{File.basename(play_zip_file)}"
  end
  _cset :play_zip_file do
    File.join('/tmp', "play-#{play_version}.zip")
  end
  _cset :play_path do
#   File.join(shared_path, "play-#{play_version}")
    abort "you must specify install path for play"
  end
  _cset :play_cmd do
    File.join(play_path, 'play')
  end
  _cset :play_preserve_zip, true
  _cset :play_daemonize_method, :play
  _cset :play_daemon do
    daemonize.__send__(play_daemonize_method)
  end

  namespace :setup do
    desc "install play if needed"
    task :default do
      transaction {
        install_play
        play_daemon.setup
      }
    end

    task :install_play do
      on_rollback {
        files = [ play_path ]
        files << play_zip_file unless play_preserve_zip
        run "rm -rf #{files.join(' ')}"
      }
      run "rm -f #{play_zip_file}" unless play_preserve_zip
      run <<-E
        if ! test -d #{play_path}; then
          (test -f #{play_zip_file} || wget --no-verbose -o #{play_zip_file} #{play_zip_url}; true) &&
          unzip #{play_zip_file} -d #{File.dirname(play_path)} && test -x #{play_path}/play;
        fi
      E
      run "rm -f #{play_zip_file}" unless play_preserve_zip
    end
  end

  namespace :daemonize do
    namespace :play do
      task :setup do
        # nop
      end

      task :start do
        run "rm -f #{app_pid}" # FIXME: should check if the pid is active
        run "cd #{current_path} && nohup #{play_cmd} start -Xss2048k --deps --pid_file=#{app_pid} --%prod"
      end

      task :stop do
        run "cd #{current_path} && #{play_cmd} stop --pid_file=#{app_pid}"
      end

      task :restart do
        stop
        start
      end

      desc "view play status"
      task :status do
        run "cd #{app_path} && #{play_cmd} status --pid_file=#{app_pid}"
      end	
    end

    namespace :upstart do
      # not implemented yet
    end
  end

  desc "start play service"
  task :start do
    play_daemon.start
  end

  desc "stop play service"
  task :stop do
    play_daemon.stop
  end

  desc "restart play service"
  task :restart do
    play_daemon.restart
  end

  desc "view play status"
  task :status do
    play_daemon.status
  end	

  desc "view play pid"
  task :pid do
    run "cd #{current_path} && #{play_cmd} pid --pid_file=#{app_pid}"
  end

  desc "view play version"
  task :version do
    run "cd #{current_path} && #{play_cmd} version --pid_file=#{app_pid}"
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
