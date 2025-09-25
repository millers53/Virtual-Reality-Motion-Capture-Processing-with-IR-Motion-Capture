# Virtual-Reality-Motion-Capture-Processing-with-IR-Motion-Capture
This repository contains codes used to compare virtual reality tracker-based motion capture to IR motion capture and is supplementary material for the publication (in review) "Characterization of Upper Extremity Joint Angle Error for Virtual Reality Motion Capture Compared to Infrared Motion Capture." Codes are specific to our setup and may require editing for other uses.

Blender:
This folder contains the blender codes we used to take the position and orientation from the FBX file (VR motion capture recorded in Brekel OpenVR) and translate three virtual markers in each cardinal direction of the local coordinate system of the tracker. This code requires an exact amount of trackers and a world origin frame (recorded in an FBX capture named WORLD_VR). However, it can be modified to use different trackers and spaces.

VRtoIR Github:
This folder contains simplified MATLAB codes to process the motion capture files for Visual3D analysis. The main code is Processing_Code.m which calls out the following functions:
  CSVtoC3D: Converts the csv export from the Blender code to a c3d file. This is the only function needed if you are not combining the VR motion capture with IR motion capture.
  Transform_VRtoIR: Transforms the VR to optimize the spatial sync between the VR and IR systems.
  Sync_VRandIR: Temporally syncs the two systems based on overlapping markers
  Combine_VRandIR: Combines the VR and IR c3d files
