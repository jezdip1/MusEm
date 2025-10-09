function sendSubjectVersion(params)
% SENDSUBJECTVERSION
%   Pošle přes syncTriggerOn nejprve jméno subjektu a pak datum ve tvaru YYYYMMDD.
%
%   params.subjID  – řetězec s ID subjektu
%   params.sync    – handle / adresa do syncTriggerOn

    % 1) Sestavíme textovou zprávu: "<subjID>_<YYYYMMDD>"
    subjID  = params.subjID;
    % datestr(now,'yyyymmdd') použije lokální čas (nastavený na Europe/Prague)
    dateStr = '20250526';
    msg     = [subjID '_' dateStr];

    % 2) Převedeme na ASCII kódy (double pro syncTriggerOn)
    codes = double(msg);

    % 3) Pošleme každý kód zvlášť
    for i = 1:numel(codes)
        syncTriggerOn(params.sync, codes(i));
        % pokud by bylo třeba resetovat linku, sem můžete vložit
        % syncTriggerOff(params.sync);
        pause(0.1);  
    end
    syncTriggerOff(params.sync);
end
