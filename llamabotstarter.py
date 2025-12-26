#!/usr/bin/python3
import signal # Import signal module
import time
import subprocess

#signal handler function
def SignalHandler_SIGINT(SignalNumber,Frame):
    print('Ctrl + C was pressed, closing bot')
    quit()
    
#register the signal with Signal handler
signal.signal(signal.SIGINT,SignalHandler_SIGINT)

#infinite signal from which we have to escape
while 1: 
    subprocess.run(['lua','llamabot.lua','akuyakureijo','##anime','Bco1981','yourpassword','llama2'])
    print("sleeping 120 seconds before restarting bot")
    time.sleep(120)
    ##input("press enter to continue") 
