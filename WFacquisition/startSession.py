# Start MATLAB sessions for wide field imaging and reach-grasp-drink behavior recording
# By Fei 2023-02-21
# Automatically assign cameras to MATLAB sessions

import matlab.engine # import the MATLAB engine package
# [Get Started with MATLAB Engine API for Python](https://ch.mathworks.com/help/matlab/matlab_external/get-started-with-matlab-engine-for-python.html)
import time # import the time package

eng1 = matlab.engine.start_matlab('-desktop') # start a new MATLAB session for wide field imaging
eng2 = matlab.engine.start_matlab('-desktop') # start a new MATLAB session for behavior recording

eng1.cd(r'Z:\users\Fei\Code\WFacquisition') # change the directory to the Code folder for wide field imaging
eng1.addpath(r'C:\WFacquisition') # add the Code folder to the MATLAB path for wide field imaging
eng2.addpath(r'C:\CAMapp4') # add the CAMapp4 folder to the MATLAB path for behavior recording
eng2.cd(r'C:\CAMapp4') # change the directory to the CAMapp4 folder for behavior recording

eng1.setCAMwfTrigger(nargout=0) # set the trigger camera for wide field imaging with the first MATLAB session
eng2.imaqreset(nargout=0) # reset the image acquisition toolbox for the second MATLAB session, to release widefield imaging cameras
eng2.setCAMsBehavior(nargout=0) # set the cameras for behavior recording
eng1.imaqreset(nargout=0) # reset the image acquisition toolbox
eng1.imaqtool(nargout=0) # open the imaqtool for wide field imaging
eng2.startCL(nargout=0) # start the behavior recording

# wait for 10 hours for recording, press Ctrl+C to stop after the recording
time.sleep(36000)
