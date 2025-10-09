function [byte] = inp_32(address)

global cogent;

byte = io32(cogent.io.ioObj,address);
