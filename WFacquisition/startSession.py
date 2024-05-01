# Start MATLAB sessions for wide field imaging and behavior recording
# By Fei 2023-02-21
# Automatically assign cameras to MATLAB sessions

import matlab.engine
import time

eng1 = matlab.engine.start_matlab('-desktop') # start a new MATLAB session for wide field imaging
eng2 = matlab.engine.start_matlab('-desktop') # start a new MATLAB session for behavior recording

eng1.cd(r'Z:\users\Fei\Code\WFacquisition') # change the directory to the Code folder for wide field imaging
eng1.addpath(r'C:\WFacquisition') # add the Code folder to the MATLAB path for wide field imaging
eng2.addpath(r'C:\CAMapp4') # add the CAMapp4 folder to the MATLAB path for behavior recording
eng2.cd(r'C:\CAMapp4') # change the directory to the CAMapp4 folder for behavior recording

eng1.setCAMwfTrigger(nargout=0)
eng2.imaqreset(nargout=0)
eng2.setCAMsBehavior(nargout=0)
eng1.imaqreset(nargout=0)

eng1.imaqtool(nargout=0) # open the imaqtool for wide field imaging
eng2.startCL(nargout=0) # start the behavior recording

# wait for 10 hours for recording, press Ctrl+C to stop after the recording
time.sleep(36000)
