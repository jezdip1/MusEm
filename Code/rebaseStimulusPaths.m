function tbl = rebaseStimulusPaths(tbl, baseDir)
% rebaseStimulusPaths  Convert stale absolute Stimuli paths to this project root.
% The master schedule stores full WAV paths. When an unfinished subject is resumed
% after moving the project folder, those paths can become stale. This helper keeps
% the part below /Stimuli/ and replaces the project root.

    if ~istable(tbl) || ~ismember('WavPath', tbl.Properties.VariableNames)
        return;
    end

    wavs = tbl.WavPath;
    for i = 1:numel(wavs)
        if iscell(wavs)
            oldPath = char(wavs{i});
        else
            oldPath = char(wavs(i));
        end

        newPath = rebaseOnePath(oldPath, baseDir);

        if iscell(wavs)
            tbl.WavPath{i} = newPath;
        else
            tbl.WavPath(i) = string(newPath);
        end
    end
end

function newPath = rebaseOnePath(oldPath, baseDir)
    newPath = oldPath;
    if isempty(oldPath) || exist(oldPath,'file') == 2
        return;
    end

    normalized = strrep(oldPath, '\', '/');
    marker = '/Stimuli/';
    idx = strfind(normalized, marker);
    if isempty(idx)
        % Path may start directly with Stimuli/...
        if startsWith(normalized, 'Stimuli/')
            tail = normalized;
        else
            return;
        end
    else
        tail = normalized(idx(end)+1:end); % keep Stimuli/...
    end

    parts = strsplit(tail, '/');
    newPath = fullfile(baseDir, parts{:});
end
