function printTrialInfo(params, r)
% printTrialInfo  Print operator-side trial/stimulus info to the MATLAB console.
% This does not draw anything on the participant screen.

    try
        ts = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss.SSS'));
    catch
        ts = char(datetime('now'));
    end

    cond = char(r.Condition);
    task = char(r.TaskType);

    if logical(r.IsPractice)
        phase = 'PRACTICE';
    else
        phase = 'TEST';
    end

    stimID = NaN;
    if ismember('StimulusID', r.Properties.VariableNames)
        stimID = r.StimulusID;
    end
    if isnan(stimID)
        stimTxt = 'NA';
    else
        stimTxt = sprintf('%g', stimID);
    end

    wavPath = char(r.WavPath);
    [~, wavName, wavExt] = fileparts(wavPath);

    fprintf('[%s] subj=%s | %s | %s | block=%g | trial=%g | stimID=%s | task=%s | file=%s%s\n', ...
        ts, char(params.subjID), cond, phase, r.Block, r.TrialIndex, stimTxt, task, wavName, wavExt);
end
