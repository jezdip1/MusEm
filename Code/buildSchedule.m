function tbl = buildSchedule(cond, stimDir, nPractice, nPerBlock, nBlocks, subsetNum)
% buildSchedule  Build practice + experimental trial table for one condition.
%   cond       : 'Imp', 'Affect' or 'Em'
%   stimDir    : root folder for this condition
%   nPractice  : number of practice trials
%   nPerBlock  : number of experimental trials per block
%   nBlocks    : number of experimental blocks
%   subsetNum  : Affect/Em subset number (1 or 2)
%
% WAV files are intentionally not bundled with the code package. Before running
% the real experiment, copy them back into the expected Stimuli subfolders.
%
% For the Imp condition, TaskType is not randomized independently. It is read
% from Stimuli/Imp/imp_rating_task_map.csv, which maps stimulus Number_S1/file ID
% to Bára's selected rating_task:
%   rating_task == "piano"       -> TaskType == "type"
%   rating_task == "instruments" -> TaskType == "num"

    cond = char(cond);
    nExp = nPerBlock * nBlocks;

    cols = {'Condition','IsPractice','WavPath','StimulusID','TaskType','TrialIndex','Block'};
    tbl  = table( ...
      'Size',          [0,numel(cols)], ...
      'VariableTypes', {'string','logical','string','double','string','double','double'}, ...
      'VariableNames', cols);

    %% Practice trials -------------------------------------------------
    pracDir = fullfile(stimDir,'Practice - wav');
    P       = requireWavs(pracDir, nPractice, sprintf('%s practice', cond));
    P       = P(randperm(numel(P), nPractice));

    switch cond
      case 'Imp'
        [pIDs, ptasks] = lookupImpTaskTypes(stimDir, P, "practice");
      case 'Affect'
        pIDs   = inferStimulusIDs(P, false);
        ptasks = repmat("dim", nPractice, 1);
      case 'Em'
        pIDs   = inferStimulusIDs(P, false);
        ptasks = repmat("disc", nPractice, 1);
      otherwise
        error('Unknown condition %s', cond);
    end

    Tprac = table( ...
      repmat(string(cond), nPractice, 1), ...       % Condition
      true(nPractice,1), ...                        % IsPractice
      string(fullfile(pracDir, P)), ...             % WavPath
      pIDs(:), ...                                  % StimulusID
      string(ptasks), ...                           % TaskType
      (1:nPractice)', ...                           % TrialIndex
      zeros(nPractice,1), ...                       % Block
      'VariableNames', cols);

    %% Experimental trials --------------------------------------------
    if strcmp(cond,'Imp')
        subDir = fullfile(stimDir,'Subset Imp - wav');
    else
        subDir = fullfile(stimDir, sprintf('Subset %d - 40 - wav', subsetNum));
    end

    E = requireWavs(subDir, nExp, sprintf('%s experimental', cond));

    switch cond
      case 'Imp'
        E = E(randperm(numel(E), nExp));
        [eIDs, etasks] = lookupImpTaskTypes(stimDir, E, "experimental");
      case 'Affect'
        E = shuffleStimuliWithEmotionRunLimit(E, nExp, 2);
        eIDs   = inferStimulusIDs(E, false);
        etasks = repmat("dim", nExp, 1);
      case 'Em'
        E = shuffleStimuliWithEmotionRunLimit(E, nExp, 2);
        eIDs   = inferStimulusIDs(E, false);
        etasks = repmat("disc", nExp, 1);
      otherwise
        error('Unknown condition %s', cond);
    end

    blk = repelem((1:nBlocks)', nPerBlock);
    idx = repmat((1:nPerBlock)', nBlocks, 1);

    Texp = table( ...
      repmat(string(cond), nExp, 1), ...            % Condition
      false(nExp,1), ...                            % IsPractice
      string(fullfile(subDir, E)), ...              % WavPath
      eIDs(:), ...                                  % StimulusID
      string(etasks), ...                           % TaskType
      idx, blk, ...                                 % TrialIndex, Block
      'VariableNames', cols);

    tbl = [Tprac; Texp];
end

function names = requireWavs(folder, nNeeded, label)
    if ~exist(folder,'dir')
        error(['Missing stimulus folder for %s:\n  %s\n' ...
               'Create this folder and copy the WAV stimuli there before running.'], ...
               label, folder);
    end

    files = dir(fullfile(folder,'*.wav'));
    names = {files.name}';
    if numel(names) < nNeeded
        error(['Not enough WAV stimuli for %s. Need %d, found %d in:\n  %s\n' ...
               'The distributed code zip intentionally does not contain WAV files.'], ...
               label, nNeeded, numel(names), folder);
    end
end

function [ids, taskTypes] = lookupImpTaskTypes(stimDir, fileNames, setName)
    mapFile = fullfile(stimDir, 'imp_rating_task_map.csv');
    if ~exist(mapFile,'file')
        error(['Missing Imp rating-task map:\n  %s\n' ...
               'This CSV is required so Imp task type is assigned by stimulus ID, not randomly.'], mapFile);
    end

    M = readtable(mapFile, 'TextType', 'string');
    required = {'Set','StimulusID','TaskType'};
    for k = 1:numel(required)
        if ~ismember(required{k}, M.Properties.VariableNames)
            error('Imp rating-task map %s is missing column "%s".', mapFile, required{k});
        end
    end

    keep = strcmpi(M.Set, string(setName));
    M = M(keep,:);
    if isempty(M)
        error('Imp rating-task map %s has no rows for Set == "%s".', mapFile, setName);
    end

    validIDs = M.StimulusID;
    ids = inferStimulusIDsFromMap(fileNames, validIDs, sprintf('Imp %s', setName));
    taskTypes = strings(numel(ids),1);

    for i = 1:numel(ids)
        hit = M.StimulusID == ids(i);
        if sum(hit) ~= 1
            error('Stimulus ID %g from file "%s" has %d matching rows in %s.', ...
                  ids(i), fileNames{i}, sum(hit), mapFile);
        end

        tt = lower(strtrim(string(M.TaskType(hit))));
        if tt == "type" || tt == "num"
            taskTypes(i) = tt;
        else
            error('Invalid TaskType "%s" for stimulus ID %g in %s.', tt, ids(i), mapFile);
        end
    end
end

function ids = inferStimulusIDsFromMap(fileNames, validIDs, label)
    ids = NaN(numel(fileNames),1);
    for i = 1:numel(fileNames)
        nums = numericTokensFromFilename(fileNames{i});
        matches = nums(ismember(nums, validIDs));
        matches = unique(matches, 'stable');

        if numel(matches) ~= 1
            error(['Could not uniquely match %s WAV file to the Imp rating-task map:\n' ...
                   '  file: %s\n  numeric tokens in filename: %s\n' ...
                   'Expected exactly one token matching a StimulusID in imp_rating_task_map.csv.'], ...
                   label, fileNames{i}, mat2str(nums));
        end
        ids(i) = matches(1);
    end
end

function ids = inferStimulusIDs(fileNames, requireID)
    ids = NaN(numel(fileNames),1);
    for i = 1:numel(fileNames)
        nums = numericTokensFromFilename(fileNames{i});
        if isempty(nums)
            if requireID
                error('Could not infer numeric stimulus ID from filename: %s', fileNames{i});
            end
            ids(i) = NaN;
        else
            ids(i) = nums(end);
        end
    end
end

function nums = numericTokensFromFilename(fileName)
    [~, stem] = fileparts(fileName);
    toks = regexp(stem, '\d+', 'match');
    if isempty(toks)
        nums = [];
    else
        nums = str2double(toks);
    end
end

function out = shuffleStimuliWithEmotionRunLimit(names, nNeeded, maxRun)
    % If filenames contain recognizable emotion tokens, avoid >maxRun equal
    % labels in a row. If filenames do not encode emotion, fall back to random.
    out = names(randperm(numel(names), nNeeded));
    labels = cellfun(@inferEmotionLabel, out, 'UniformOutput', false);
    known = labels(~cellfun(@isempty, labels));
    if numel(unique(known)) < 2
        return;
    end

    for attempt = 1:5000
        cand = names(randperm(numel(names), nNeeded));
        labels = cellfun(@inferEmotionLabel, cand, 'UniformOutput', false);
        if maxConsecutive(labels) <= maxRun
            out = cand;
            return;
        end
    end
    warning('Could not enforce emotion run limit from filenames; using random order.');
end

function label = inferEmotionLabel(filename)
    [~, stem] = fileparts(filename);
    s = lower(stem);

    if containsAny(s, {'happiness','happy','joy','radost','vesel'})
        label = 'joy';
    elseif containsAny(s, {'sadness','sad','smutek','smut'})
        label = 'sad';
    elseif containsAny(s, {'fear','fearful','strach'})
        label = 'fear';
    elseif containsAny(s, {'tenderness','tender','neha','něha'})
        label = 'tender';
    elseif containsAny(s, {'neutral','neutralni','neutrální'})
        label = 'neutral';
    else
        label = '';
    end
end

function tf = containsAny(s, patterns)
    tf = false;
    for i = 1:numel(patterns)
        if contains(s, patterns{i})
            tf = true;
            return;
        end
    end
end

function m = maxConsecutive(labels)
    if isempty(labels)
        m = 0;
        return;
    end
    m = 1;
    runLen = 1;
    for i = 2:numel(labels)
        if ~isempty(labels{i}) && strcmp(labels{i}, labels{i-1})
            runLen = runLen + 1;
        else
            runLen = 1;
        end
        m = max(m, runLen);
    end
end
