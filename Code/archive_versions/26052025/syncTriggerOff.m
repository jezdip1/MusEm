% syncTriggerOff.m
function syncTriggerOff(syncInfo)
% syncTriggerOff  –  Clear the sync line (drive back to 0).
    switch syncInfo.method
        case 'ppdev_mex'
            ppdev_mex('Write', syncInfo.ppdevPortNum, 0);

        case 'io64'
            io64(syncInfo.ioObj, syncInfo.portAddr, 0);

        case 'pico'
            write(syncInfo.serial, uint8(0), 'uint8');

        otherwise
            % none → no‐op
    end
end
