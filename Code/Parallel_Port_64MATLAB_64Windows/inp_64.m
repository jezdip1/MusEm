function [byte] = inp_64(address)

global cogent;

byte = io64(cogent.io.ioObj,address);
