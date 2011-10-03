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

#################################################
# MANDATORY CONFIG TO SET 
set :application, "PUT YOUR APPLICATION NAME HERE"	# the name of the play application in general
set :repository,  "PUT YOUR VCS REPOSITORY URL HERE"	# for ex: ssh://xxx@github.com/git/xxx/yyy.git

set :scm, :git 				# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :deploy_to, "THE REMOTE DIR"	# the directory where capistrano will setup it's env and clone your VCS and deploy current version etc...
					# read this for more info about Capistrano deploy https://github.com/mpasternacki/capistrano-documentation-support-files/raw/master/default-execution-path/Capistrano%20Execution%20Path.jpg
set :play_path, "THE PLAY PATH"		# this is the path in which play/play.bat can be found

#################################################
# You can let it like that
set :shared_path, "#{deploy_to}/shared"
set :app_pid, "#{shared_path}/pids/server.pid"
set :app_path, "#{deploy_to}/current"

#################################################
# MANDATORY SERVER CONFIG TO SET 
set :domain, "IP:PORT or URL of your remove server"
set :user, "YOUR SSH USERNAME"

role :web, domain                          # Your HTTP server, Apache/etc
role :app, domain                          # This may be the same as your `Web` server
role :db,  domain, :primary => true 	   # This is where Rails migrations will run


