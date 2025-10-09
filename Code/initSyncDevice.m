function syncInfo = initSyncDevice(ppdevPortNum, picoPort)
% initSyncDevice  –  Probe and open a sync‐pulse output device.
%   syncInfo = initSyncDevice()                uses ppdev port 1 & '/dev/ttyACM0'
%   syncInfo = initSyncDevice(ppdevPortNum)    override parallel‐port index
%   syncInfo = initSyncDevice(ppdevPortNum,picoPort) override pico path
%
% syncInfo.method ∈ {'ppdev_mex','io64','pico','none'}

    if nargin<1, ppdevPortNum = 1; end
    if nargin<2, picoPort    = '/dev/ttyACM0'; end

    % record which methods actually succeeded
    avail = struct('ppdev_mex',false,'io64',false,'pico',false);

    % --- try each in turn ---
    if isunix
        % ppdev-mex
        try
            addpath('./ppdev-mex/'); 
            ppdev_mex('Open', ppdevPortNum);
            avail.ppdev_mex = true;
        catch
        end
        % pico
        try
            sp = serialport(picoPort,115200);
            avail.pico = true;
        catch
        end

    else  % Windows
        % io64 / InpOutX
        try
            config_io_64;             % InpOutX
            [err, ioObj] = io64;
            if err==0
                avail.io64 = true;
            end
        catch
        end
    end

    % --- pick the method ---
    methods = {}; 
    if avail.ppdev_mex, methods{end+1} = 'ppdev_mex'; end
    if avail.io64,      methods{end+1} = 'io64';      end
    if avail.pico,      methods{end+1} = 'pico';      end
    methods{end+1} = 'none';  % always an option

    % if only one real + none, just pick the real one
    realMethods = setdiff(methods,'none');
    if numel(realMethods)==1
        chosen = realMethods{1};
    else
        % prompt user in console
        fprintf('Multiple sync‐methods detected:\n');
        for i=1:numel(methods)
            fprintf('  %d) %s\n', i, methods{i});
        end
        idx = input(sprintf('Select sync method [1–%d]: ', numel(methods)));
        if isempty(idx) || idx<1 || idx>numel(methods)
            chosen = 'none';
        else
            chosen = methods{idx};
        end
    end

    % --- assemble syncInfo ---
    syncInfo = struct('method',chosen);
    switch chosen
        case 'ppdev_mex'
            syncInfo.ppdevPortNum = ppdevPortNum;
        case 'io64'
            syncInfo.ioObj    = ioObj;            
            syncInfo.portAddr = hex2dec('378');
        case 'pico'
            syncInfo.serial   = sp;               
        case 'none'
            % nothing else needed
    end

    fprintf('Using sync method: %s\n', chosen);
end
