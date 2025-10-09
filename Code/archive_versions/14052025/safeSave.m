function safeSave(params)
try
    save(params.dataFile,'params','-v7');   % jediný příkaz navíc
catch ME
    warning('Uložení se nezdařilo: %s',ME.message);
end
end