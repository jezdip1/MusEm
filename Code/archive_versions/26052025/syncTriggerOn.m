% syncTriggerOn.m
function syncTriggerOn(syncInfo, code)
% syncTriggerOn  –  Assert the sync line to `code` (0–255).
    switch syncInfo.method
        case 'ppdev_mex'
            ppdev_mex('Write', syncInfo.ppdevPortNum, code);

        case 'io64'
            io64(syncInfo.ioObj, syncInfo.portAddr, code);

        case 'pico'
            write(syncInfo.serial, uint8(code), 'uint8');

        otherwise
            % none → no‐op
    end
end
