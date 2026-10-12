function safeSave(params)
% safeSave  Persist the full MATLAB state and export human-readable audit CSVs.
%
% Timing note:
%   This function is called only after a trial has already finished and the new
%   row has been appended to params.resultsTable.  It deliberately does not sit
%   inside stimulus presentation, fixation, audio playback, or trigger-dispatch
%   code paths.
try
    % Save behavioral state, not handles tied to the old MATLAB process.
    stored = params;
    for field = {'sync','joy','audioReader','pahandle','win'}
        if isfield(stored,field{1}), stored.(field{1}) = []; end
    end
    toSave = struct('params',stored);
    save(params.dataFile,'-struct','toSave','-v7');
catch ME
    warning('Uložení se nezdařilo: %s',ME.message);
end

try
    writeMusEmAuditCSVs(params);
catch ME
    warning('CSV/audit export se nezdařil: %s',ME.message);
end
end
