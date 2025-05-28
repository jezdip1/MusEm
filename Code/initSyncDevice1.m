% initSyncDevice.m
function syncInfo = initSyncDevice(ppdevPortNum, picoPort)
% initSyncDevice  –  Probe for and open a sync‐pulse output device.
%   syncInfo = initSyncDevice()                % uses defaults: ppdev port 1, pico '/dev/ttyACM0'
%   syncInfo = initSyncDevice(ppdevPortNum)    % override parallel‐port index
%   syncInfo = initSyncDevice(ppdevPortNum,picoPort) % override pico serial path
%
% syncInfo.method ∈ {'ppdev_mex','io64','pico','none'}
% + fields needed by the chosen method:
%   .ppdevPortNum    (for ppdev_mex)
%   .ioObj, .portAddr (for io64/InOut)
%   .serial          (for pico)

    if nargin<1, ppdevPortNum = 1; end
    if nargin<2, picoPort    = '/dev/ttyACM0'; end

    syncInfo.method = 'none';

    if isunix
        % 1) Try Linux parallel port via ppdev-mex
        try
            addpath('./ppdev-mex/');
            ppdev_mex('Open', ppdevPortNum);
            syncInfo.method      = 'ppdev_mex';
            syncInfo.ppdevPortNum = ppdevPortNum;
            return;
        catch
        end

        % 2) Fallback: RPi Pico via serialport
        try
            syncInfo.serial = serialport(picoPort,115200);
            syncInfo.method = 'pico';
            return;
        catch
        end

    else  % Windows
        % 3) Try InpOutX via io64
        try
            config_io_64;                % load driver
            [err, ioObj] = io64;         % init io64
            if err==0
                syncInfo.method   = 'io64';
                syncInfo.ioObj    = ioObj;
                syncInfo.portAddr = hex2dec('378');  % standard LPT1
                return;
            end
        catch
        end
    end

    warning('initSyncDevice: no sync port found; syncInfo.method="none"');
end
