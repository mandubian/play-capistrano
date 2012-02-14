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

require 'erb'

# without this, there are problems with sudo on remote server
default_run_options[:pty] = true

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    play.start
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    play.restart
  end

  task :stop, :roles => :app, :except => { :no_release => true } do
    play.stop
  end
end

after 'deploy:setup', 'play:setup'
after 'deploy:finalize_update', 'play:update'

namespace :play do
  _cset :play_version, '1.2.4'
  _cset :play_zip_url do
    "http://download.playframework.org/releases/#{File.basename(play_zip_file)}"
  end
  _cset :play_preserve_zip, true
  _cset :play_zip_file do
    File.join(shared_path, "play-#{play_version}.zip")
  end
  _cset :play_path do
    File.join(shared_path, "play-#{play_version}")
  end
  _cset :play_cmd do
    File.join(play_path, 'play')
  end
  _cset :play_daemonize_method, :play
  _cset :play_daemon do
    daemonize.__send__(play_daemonize_method)
  end
  _cset :play_pid_file do
    fetch(:app_pid, File.join(shared_path, 'pids', 'server.pid')) # for backward compatibility
  end
  _cset :play_use_precompile, true # performe precompilation before restarting service if true

  namespace :setup do
    desc "install play if needed"
    task :default, :except => { :no_release => true } do
      transaction {
        setup_ivy if fetch(:play_setup_ivy, false)
        install_play
      }
      transaction {
        play_daemon.setup
      }
    end

    _cset :play_ivy_settings_template, File.join(File.dirname(__FILE__), 'templates', 'ivysettings.erb')
    _cset :play_ivy_settings do
      File.join(capture('echo $HOME').chomp, '.ivy2', 'ivysettings.xml')
    end
    task :setup_ivy, :roles => :app, :except => { :no_release => true } do
      tempfile = File.join('/tmp', File.basename(play_ivy_settings))
      on_rollback {
        run "rm -f #{tempfile}"
      }
      template = File.read(play_ivy_settings_template)
      result = ERB.new(template).result(binding)
      run "test -d #{File.dirname(play_ivy_settings)} || mkdir -p #{File.dirname(play_ivy_settings)}"
      put result, tempfile
      run "diff #{tempfile} #{play_ivy_settings} || mv -f #{tempfile} #{play_ivy_settings}"
    end

    task :install_play, :roles => :app, :except => { :no_release => true } do
      temp_zip = File.join('/tmp', File.basename(play_zip_file))
      temp_dir = File.join('/tmp', File.basename(play_zip_file, '.zip'))
      on_rollback {
        files = [ play_path, temp_zip, temp_dir ]
        files << play_zip_file unless play_preserve_zip
        run "#{try_sudo} rm -rf #{files.join(' ')}"
      }
      run "#{try_sudo} rm -f #{play_zip_file}" unless play_preserve_zip

      run <<-E
        ( test -f #{play_zip_file} ||
          ( wget --no-verbose -O #{temp_zip} #{play_zip_url} && #{try_sudo} mv -f #{temp_zip} #{play_zip_file}; true ) ) &&
        ( test -d #{play_path} ||
          ( unzip #{play_zip_file} -d /tmp && #{try_sudo} mv -f #{temp_dir} #{play_path}; true ) ) &&
        test -x #{play_cmd};
      E
      run "#{try_sudo} rm -f #{play_zip_file}" unless play_preserve_zip
    end
  end

  namespace :daemonize do
    namespace :play do
      task :setup, :roles => :app, :except => { :no_release => true } do
        # nop
      end

      _cset :play_start_options do
        options = []
        options << "-Xss2048k"
        options << "--%prod"
        options
      end
      task :start, :roles => :app, :except => { :no_release => true } do
        run "rm -f #{play_pid_file}" # FIXME: should check if the pid is active
        play_start_options << "-Dprecompiled=true" if play_use_precompile
        run "cd #{release_path} && nohup #{play_cmd} start --pid_file=#{play_pid_file} #{play_start_options.join(' ')}"
      end

      task :stop, :roles => :app, :except => { :no_release => true } do
        run "cd #{release_path} && #{play_cmd} stop --pid_file=#{play_pid_file}"
      end

      task :restart, :roles => :app, :except => { :no_release => true } do
        stop
        start
      end

      task :status, :roles => :app, :except => { :no_release => true } do
        run "cd #{release_path} && #{play_cmd} status --pid_file=#{play_pid_file}"
      end	
    end

    namespace :upstart do
      _cset :play_upstart_service do
        application
      end
      _cset :play_upstart_config do
        File.join('/etc', 'init', "#{play_upstart_service}.conf")
      end
      _cset :play_upstart_config_template, File.join(File.dirname(__FILE__), 'templates', 'upstart.erb')
      _cset :play_upstart_options do
        options = []
        options << "-Xss2048k"
        options << "--%prod"
        options
      end
      _cset :play_upstart_runner do
        user
      end

      task :setup, :roles => :app, :except => { :no_release => true } do
        tempfile = File.join('/tmp', File.basename(play_upstart_config))
        on_rollback {
          run "rm -f #{tempfile}"
        }
        play_upstart_options << "-Dprecompiled=true" if play_use_precompile
        template = File.read(play_upstart_config_template)
        result = ERB.new(template).result(binding)
        put result, tempfile
        run "diff #{tempfile} #{play_upstart_config} || #{sudo} mv -f #{tempfile} #{play_upstart_config}"
      end

      task :start, :roles => :app, :except => { :no_release => true } do
        run "#{sudo} service #{play_upstart_service} start"
      end

      task :stop, :roles => :app, :except => { :no_release => true } do
        run "#{sudo} service #{play_upstart_service} stop"
      end

      task :restart, :roles => :app, :except => { :no_release => true } do
        run "#{sudo} service #{play_upstart_service} restart || #{sudo} service #{play_upstart_service} start"
      end

      task :status, :roles => :app, :except => { :no_release => true } do
        run "#{sudo} service #{play_upstart_service} status"
      end
    end
  end

  desc "update play runtime environment"
  task :update, :roles => :app, :except => { :no_release => true } do
    # FIXME: made tmp/ group writable since deploy:finalize_update creates non-group-writable tmp/
    run "#{try_sudo} chmod g+w #{release_path}/tmp" if fetch(:group_writable, true)

    transaction {
      dependencies
      precompile if play_use_precompile
    }
  end

  task :dependencies, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && #{play_cmd} dependencies --forProd"
  end

  task :precompile, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && #{play_cmd} precompile"
  end

  desc "start play service"
  task :start, :roles => :app, :except => { :no_release => true } do
    play_daemon.start
  end

  desc "stop play service"
  task :stop, :roles => :app, :except => { :no_release => true } do
    play_daemon.stop
  end

  desc "restart play service"
  task :restart, :roles => :app, :except => { :no_release => true } do
    play_daemon.restart
  end

  desc "view play status"
  task :status, :roles => :app, :except => { :no_release => true } do
    play_daemon.status
  end	

  desc "view play pid"
  task :pid, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && #{play_cmd} pid --pid_file=#{play_pid_file}"
  end

  desc "view play version"
  task :version, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && #{play_cmd} version --pid_file=#{play_pid_file}"
  end	

  desc "view running play apps"
  task :ps, :roles => :app, :except => { :no_release => true } do
    run "ps -eaf | grep 'play'"
  end

  desc "kill play processes"
  task :kill, :roles => :app, :except => { :no_release => true } do
    run "ps -ef | grep 'play' | grep -v 'grep' | awk '{print $2}'| xargs -i kill {} ; echo ''"
  end

  desc "view logfiles"
  task :logs, :roles => :app, :except => { :no_release => true } do
    run "tail -f #{shared_path}/log/#{application}.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

end
