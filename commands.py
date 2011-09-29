# Capistano commands

import sys
import os, os.path
import fileinput
import shutil

import getopt
from play.utils import *

MODULE = "capistrano"

COMMANDS = ["capify"]

HELP = {
    "capify:": "Adds the files needed to deploy/run remotely Play with capistrano"
}

def execute(**kargs):
    command = kargs.get("command")
    app = kargs.get("app")
    args = kargs.get("args")
    env = kargs.get("env")

    if command == 'capify':
	mf = os.path.join(app.path, 'modules')
	for module in app.modules():
	    if("capistrano" in module): 
	        print "Copying Capistrano Capfile..."
	        shutil.copyfile(os.path.join(module, "Capfile"), os.path.join(app.path, "Capfile"))
	        print "Copying Capistrano Play recipes..."
	        shutil.copyfile(os.path.join(module, "conf", "play-recipes.rb"), os.path.join(app.path, "conf", "play-recipes.rb"))
		
		if(not os.path.exists(os.path.join(app.path, "conf", "deploy.rb"))):
			print "Copying Capistrano Play deploy config..."
		        shutil.copyfile(os.path.join(module, "conf", "deploy.rb"), os.path.join(app.path, "conf", "deploy.rb"))
		else: print "Capistrano Play deploy config already exists so NOT copying it..."
	        print "Copying Play remote background launcher script..."
	        shutil.copyfile(os.path.join(module, "run.sh"), os.path.join(app.path, "run.sh"))
	        print "Now go edit your remote configs in conf/deploy.rb"
        #print "~ Use: --css to override the Secure css"       
        #print "~ "
        #return

#    try:
#        optlist, args2 = getopt.getopt(args, '', ['css', 'login', 'layout'])
#        for o, a in optlist:
#            if o == '--css':
#                app.override('public/stylesheets/secure.css', 'public/stylesheets/secure.css')
#                print "~ "
#                return

#    except getopt.GetoptError, err:
#        print "~ %s" % str(err)
#        print "~ "
#        sys.exit(-1)
