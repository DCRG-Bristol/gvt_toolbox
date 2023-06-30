# GVT Toolbox
v1.0.0.0

A Matlab based toolbox to complete roving hammer GVTs of generic structures.

This package contains two namespaces

gvt.daq - used to collect GVT data and store in a pre-defined structure

gvt.PostProc - used to analysis the results of the GVT

## Getting started

Clone the repository using `git clone https://github.com/farg-bristol/gvt_toolbox.git`.

To use this pacakage the folder 'tbx' must be on the matlab path, to do this either:

1. Use the MATLAB Package Managaer (mpm) (https://github.com/DCRG-Bristol/mpm)
    run the command 
    `mpm install gvt_toolbox -u path\to\toolbox --local -e --force`
    This command only needs to be run once. For future restarts of MATLAB either run the command
    `mpm init`
    or add it to the the startup.m script
2. Manually add the folder using the `addpath` function / right clicking in the GUI

Please read the documentation in the doc folder for info on how to use the package

## Dependencies
This package utilises the matlab DAQ toolbox to collect data from GVTs

## Change Log
All changes between versions are noted in the file "changelog.txt"



