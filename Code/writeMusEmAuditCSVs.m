function writeMusEmAuditCSVs(params)
% writeMusEmAuditCSVs  Export CSV audit files for MusEm after safeSave().
%
% The exporter is intentionally post-trial only.  It reconstructs the audit log
% from params.resultsTable and params.masterSchedule, including trigger onset
% timestamps that are already stored by the trial functions.  It does not add
% any code to the fixation/stimulus/audio/trigger timing path.

    if nargin < 1 || ~isstruct(params)
        return;
    end
    if ~isfield(params,'resultsDir') || isempty(params.resultsDir)
        return;
    end

    subjID = "UNKNOWN";
    if isfield(params,'subjID') && ~isempty(params.subjID)
        subjID = string(params.subjID);
    end
    subjStem = sanitizeFileStem(subjID);

    auditDir = fullfile(params.resultsDir, 'Audit', char(subjStem));
    if ~exist(auditDir,'dir')
        mkdir(auditDir);
    end

    % 1) Direct human-readable table exports.
    if isfield(params,'resultsTable') && istable(params.resultsTable)
        writetable(params.resultsTable, fullfile(auditDir, char(subjStem + "_resultsTable.csv")));
    end

    if isfield(params,'masterSchedule') && istable(params.masterSchedule)
        writetable(params.masterSchedule, fullfile(auditDir, char(subjStem + "_masterSchedule.csv")));
    end

    trigMap = getMusEmTriggerCodeMap();
    writetable(trigMap, fullfile(auditDir, char(subjStem + "_triggerCodeMap.csv")));

    % 2) Long-format event log reconstructed from the saved results.
    if isfield(params,'resultsTable') && istable(params.resultsTable)
        eventLog = buildMusEmEventLog(params, trigMap);
        writetable(eventLog, fullfile(auditDir, char(subjStem + "_eventLog.csv")));
        writeMusEmAuditSummary(params, eventLog, auditDir, subjStem);
    end
end

function eventLog = buildMusEmEventLog(params, trigMap)
    varNames = {'SubjID','Condition','IsPractice','Block','TrialIndex','StimulusID', ...
                'TaskType','WavPath','EventTime','EventType','EventName', ...
                'TriggerCode','Value','RT_s','Notes'};

    eventLog = table( ...
        strings(0,1), strings(0,1), false(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
        strings(0,1), strings(0,1), NaT(0,1), strings(0,1), strings(0,1), ...
        zeros(0,1), strings(0,1), zeros(0,1), strings(0,1), ...
        'VariableNames', varNames);

    R = params.resultsTable;
    if isempty(R)
        return;
    end

    for i = 1:height(R)
        r = R(i,:);
        subjID     = rowString(r, 'SubjID', getDefaultSubject(params));
        condition  = rowString(r, 'Condition', "");
        isPractice = rowLogical(r, 'IsPractice', false);
        block      = rowDouble(r, 'Block', NaN);
        trialIndex = rowDouble(r, 'TrialIndex', NaN);
        taskType   = rowString(r, 'TaskType', "");
        wavPath    = rowString(r, 'WavPath', "");
        stimID     = lookupStimulusID(params, r);

        trialLabel = "test";
        if isPractice
            trialLabel = "practice";
        end

        eventLog = appendEvent(eventLog, subjID, condition, isPractice, block, trialIndex, stimID, ...
            taskType, wavPath, NaT, "trial", "trial_row_saved", NaN, "", NaN, ...
            sprintf('phase=%s; row=%d in resultsTable', char(trialLabel), i));

        % Trigger/event timestamps already stored by the trial functions.
        for j = 1:height(trigMap)
            eventName = char(trigMap.TriggerName(j));
            if ismember(eventName, R.Properties.VariableNames)
                t = rowDatetime(r, eventName);
                if isValidDateTime(t)
                    eventLog = appendEvent(eventLog, subjID, condition, isPractice, block, trialIndex, stimID, ...
                        taskType, wavPath, t, "trigger", trigMap.TriggerName(j), trigMap.TriggerCode(j), ...
                        "", NaN, "timestamp from resultsTable trigger-onset column");
                end
            end
        end

        % Behavioral responses / what was selected.
        switch lower(char(condition))
            case 'imp'
                taskOnset = firstValidDatetime(r, { ...
                    'ImpPracticeAnsweringNumOnset','ImpPracticeAnsweringTypeOnset', ...
                    'ImpTrialAnsweringNumOnset','ImpTrialAnsweringTypeOnset'});
                rtTask = rowDouble(r, 'RtTask', NaN);
                eventLog = appendEvent(eventLog, subjID, condition, isPractice, block, trialIndex, stimID, ...
                    taskType, wavPath, addRT(taskOnset, rtTask), "response", "ImpTaskResponse", ...
                    NaN, rowString(r, 'Resp', ""), rtTask, "two-button response; time = response-screen onset + RT when available");

                loadOnset = firstValidDatetime(r, { ...
                    'ImpPracticeAnsweringLoadNumOnset','ImpPracticeAnsweringLoadTypeOnset', ...
                    'ImpTrialAnsweringLoadNumOnset','ImpTrialAnsweringLoadTypeOnset'});
                rtLoad = rowDouble(r, 'RtLoad', NaN);
                eventLog = appendEvent(eventLog, subjID, condition, isPractice, block, trialIndex, stimID, ...
                    taskType, wavPath, addRT(loadOnset, rtLoad), "response", "ImpLoadRating", ...
                    NaN, numberAsString(rowDouble(r, 'LoadRating', NaN)), rtLoad, ...
                    "load scale response; time = load-screen onset + RT when available");

            case 'affect'
                value = sprintf('Pref=%s;Arousal=%s;Valence=%s', ...
                    numberAsString(rowDouble(r,'Pref',NaN)), ...
                    numberAsString(rowDouble(r,'Arousal',NaN)), ...
                    numberAsString(rowDouble(r,'Valence',NaN)));
                eventLog = appendEvent(eventLog, subjID, condition, isPractice, block, trialIndex, stimID, ...
                    taskType, wavPath, rowDatetime(r, 'TimeTrialEnd'), "response", "AffectRatingsSubmitted", ...
                    NaN, string(value), rowDouble(r,'RtDim',NaN), ...
                    "final dimensional ratings; time = trial-end save timestamp");

            case 'em'
                value = sprintf('Pref=%s;Emotion=%s', ...
                    numberAsString(rowDouble(r,'Pref',NaN)), rowString(r,'Emotion',""));
                eventLog = appendEvent(eventLog, subjID, condition, isPractice, block, trialIndex, stimID, ...
                    taskType, wavPath, rowDatetime(r, 'TimeTrialEnd'), "response", "EmRatingsSubmitted", ...
                    NaN, string(value), rowDouble(r,'RtEm',NaN), ...
                    "final discrete-emotion ratings; time = trial-end save timestamp");
        end
    end

    if ~isempty(eventLog)
        try
            isTimed = ~isnat(eventLog.EventTime);
            timedRows = eventLog(isTimed,:);
            untimedRows = eventLog(~isTimed,:);
            if ~isempty(timedRows)
                timedRows = sortrows(timedRows, 'EventTime');
            end
            eventLog = [timedRows; untimedRows];
        catch
            % Keep insertion order if sortrows fails for any MATLAB-version reason.
        end
    end
end

function T = appendEvent(T, subjID, condition, isPractice, block, trialIndex, stimID, taskType, wavPath, eventTime, eventType, eventName, triggerCode, value, rt, notes)
    if nargin < 16 || isempty(notes), notes = ""; end
    if nargin < 15 || isempty(rt), rt = NaN; end
    if nargin < 14 || isempty(value), value = ""; end
    if nargin < 13 || isempty(triggerCode), triggerCode = NaN; end
    if nargin < 9 || isempty(wavPath), wavPath = ""; end
    if nargin < 8 || isempty(taskType), taskType = ""; end
    if nargin < 7 || isempty(stimID), stimID = NaN; end
    if nargin < 6 || isempty(trialIndex), trialIndex = NaN; end
    if nargin < 5 || isempty(block), block = NaN; end
    if nargin < 4 || isempty(isPractice), isPractice = false; end
    if nargin < 3 || isempty(condition), condition = ""; end
    if nargin < 2 || isempty(subjID), subjID = ""; end
    if nargin < 10 || isempty(eventTime), eventTime = NaT; end

    if ~isnumeric(triggerCode), triggerCode = str2double(string(triggerCode)); end
    if ~isnumeric(rt), rt = str2double(string(rt)); end

    row = table(string(subjID), string(condition), logical(isPractice), double(block), double(trialIndex), double(stimID), ...
        string(taskType), string(wavPath), eventTime, string(eventType), string(eventName), ...
        double(triggerCode), string(value), double(rt), string(notes), ...
        'VariableNames', T.Properties.VariableNames);
    T = [T; row];
end

function trigMap = getMusEmTriggerCodeMap()
    names = {};
    codes = [];
    try
        names = properties('TriggerCodes');
        codes = zeros(numel(names),1);
        for i = 1:numel(names)
            codes(i) = double(eval(sprintf('TriggerCodes.%s', names{i})));
        end
    catch
        names = { ...
            'ImpPracticeFixBaselineOnset','ImpPracticeSubQuestionNumOnset','ImpPracticeSubQuestionTypeOnset', ...
            'ImpPracticePlaySoundOnset','ImpPracticeStopSoundOnset','ImpPracticeAnsweringNumOnset', ...
            'ImpPracticeAnsweringTypeOnset','ImpTrialFixBaselineOnset','ImpTrialSubQuestionNumOnset', ...
            'ImpTrialSubQuestionTypeOnset','ImpTrialPlaySoundOnset','ImpTrialStopSoundOnset', ...
            'ImpTrialAnsweringNumOnset','ImpTrialAnsweringTypeOnset','ImpPracticeAnsweringLoadNumOnset', ...
            'ImpPracticeAnsweringLoadTypeOnset','ImpTrialAnsweringLoadNumOnset','ImpTrialAnsweringLoadTypeOnset', ...
            'AffPracticeFixBaselineOnset','AffPracticePlaySoundOnset','AffPracticeStopSoundOnset', ...
            'AffPracticeAnsweringPrefOnset','AffPracticeAnsweringArousalOnset','AffPracticeAnsweringValenceOnset', ...
            'AffTrialFixBaselineOnset','AffTrialPlaySoundOnset','AffTrialStopSoundOnset', ...
            'AffTrialAnsweringPrefOnset','AffTrialAnsweringArousalOnset','AffTrialAnsweringValenceOnset', ...
            'EmPracticeFixBaselineOnset','EmPracticePlaySoundOnset','EmPracticeStopSoundOnset', ...
            'EmPracticeAnsweringPrefOnset','EmPracticeAnsweringEmotionOnset','EmTrialFixBaselineOnset', ...
            'EmTrialPlaySoundOnset','EmTrialStopSoundOnset','EmTrialAnsweringPrefOnset','EmTrialAnsweringEmotionOnset'};
        codes = [1 7 14 20 27 33 39 46 52 58 65 71 78 84 90 97 103 110 ...
                 116 122 129 135 141 148 154 161 167 173 180 186 ...
                 193 199 205 212 218 224 231 237 244 250]';
    end

    trigMap = table(string(names(:)), double(codes(:)), 'VariableNames', {'TriggerName','TriggerCode'});
    try
        trigMap = sortrows(trigMap, 'TriggerCode');
    catch
    end
end

function writeMusEmAuditSummary(params, eventLog, auditDir, subjStem)
    summaryFile = fullfile(auditDir, char(subjStem + "_auditSummary.txt"));
    fid = fopen(summaryFile, 'w');
    if fid < 0
        return;
    end
    cleanupObj = onCleanup(@() fclose(fid));

    fprintf(fid, 'MusEm audit export summary\n');
    fprintf(fid, 'Generated: %s\n', char(datetime('now','Format','yyyy-MM-dd HH:mm:ss.SSS')));
    if isfield(params,'subjID')
        fprintf(fid, 'Subject: %s\n', char(string(params.subjID)));
    end
    if isfield(params,'dataFile')
        fprintf(fid, 'MAT file: %s\n', char(string(params.dataFile)));
    end

    if isfield(params,'resultsTable') && istable(params.resultsTable)
        fprintf(fid, 'resultsTable rows: %d\n', height(params.resultsTable));
    end
    if isfield(params,'masterSchedule') && istable(params.masterSchedule)
        fprintf(fid, 'masterSchedule rows: %d\n', height(params.masterSchedule));
    end
    fprintf(fid, 'eventLog rows: %d\n', height(eventLog));
    if ~isempty(eventLog)
        fprintf(fid, 'trigger events: %d\n', sum(strcmp(eventLog.EventType,'trigger')));
        fprintf(fid, 'response events: %d\n', sum(strcmp(eventLog.EventType,'response')));
    end
    fprintf(fid, '\nFiles in this folder:\n');
    fprintf(fid, '- *_resultsTable.csv: direct CSV export of params.resultsTable\n');
    fprintf(fid, '- *_masterSchedule.csv: direct CSV export of params.masterSchedule\n');
    fprintf(fid, '- *_triggerCodeMap.csv: symbolic trigger names and numeric codes\n');
    fprintf(fid, '- *_eventLog.csv: long-format audit log reconstructed from results timestamps\n');
    fprintf(fid, '\nTiming note:\n');
    fprintf(fid, 'CSV/audit export runs only from safeSave(), after a trial row has been appended.\n');
    fprintf(fid, 'No trigger values, WaitSecs durations, audio playback calls, or stimulus-presentation calls are changed by the audit exporter.\n');
end

function subjID = getDefaultSubject(params)
    subjID = "";
    if isfield(params,'subjID') && ~isempty(params.subjID)
        subjID = string(params.subjID);
    end
end

function s = sanitizeFileStem(s)
    s = string(s);
    if strlength(s) == 0
        s = "UNKNOWN";
    end
    s = regexprep(s, '[^A-Za-z0-9_\-]+', '_');
end

function s = rowString(r, varName, defaultValue)
    if nargin < 3, defaultValue = ""; end
    if ~ismember(varName, r.Properties.VariableNames)
        s = string(defaultValue);
        return;
    end
    v = r.(varName);
    if iscell(v)
        v = v{1};
    end
    if isempty(v)
        s = string(defaultValue);
    elseif isstring(v)
        s = v(1);
    elseif ischar(v)
        s = string(v);
    elseif isnumeric(v) || islogical(v)
        s = string(v(1));
    else
        try
            s = string(v(1));
        catch
            s = string(defaultValue);
        end
    end
end

function x = rowDouble(r, varName, defaultValue)
    if nargin < 3, defaultValue = NaN; end
    if ~ismember(varName, r.Properties.VariableNames)
        x = defaultValue;
        return;
    end
    v = r.(varName);
    if iscell(v), v = v{1}; end
    if isempty(v)
        x = defaultValue;
    elseif isnumeric(v) || islogical(v)
        x = double(v(1));
    else
        x = str2double(string(v(1)));
        if isnan(x), x = defaultValue; end
    end
end

function x = rowLogical(r, varName, defaultValue)
    if nargin < 3, defaultValue = false; end
    if ~ismember(varName, r.Properties.VariableNames)
        x = defaultValue;
        return;
    end
    v = r.(varName);
    if iscell(v), v = v{1}; end
    if isempty(v)
        x = defaultValue;
    elseif islogical(v)
        x = logical(v(1));
    elseif isnumeric(v)
        x = v(1) ~= 0;
    else
        x = any(strcmpi(strtrim(string(v(1))), {'1','true','yes','y'}));
    end
end

function t = rowDatetime(r, varName)
    t = NaT;
    if ~ismember(varName, r.Properties.VariableNames)
        return;
    end
    v = r.(varName);
    if iscell(v), v = v{1}; end
    if isempty(v)
        return;
    end
    if isa(v,'datetime')
        t = v(1);
    else
        try
            t = datetime(v(1));
        catch
            t = NaT;
        end
    end
end

function tf = isValidDateTime(t)
    tf = isa(t,'datetime') && isscalar(t) && ~isnat(t);
end

function t = firstValidDatetime(r, varNames)
    t = NaT;
    for i = 1:numel(varNames)
        cand = rowDatetime(r, varNames{i});
        if isValidDateTime(cand)
            t = cand;
            return;
        end
    end
end

function t = addRT(t0, rt)
    if isValidDateTime(t0) && isnumeric(rt) && isscalar(rt) && ~isnan(rt)
        t = t0 + seconds(rt);
    else
        t = NaT;
    end
end

function s = numberAsString(x)
    if isnumeric(x) && isscalar(x) && ~isnan(x)
        s = sprintf('%g', x);
    else
        s = "";
    end
end

function stimID = lookupStimulusID(params, r)
    stimID = NaN;
    if ismember('StimulusID', r.Properties.VariableNames)
        stimID = rowDouble(r, 'StimulusID', NaN);
        if ~isnan(stimID)
            return;
        end
    end
    if ~isfield(params,'masterSchedule') || ~istable(params.masterSchedule)
        return;
    end
    M = params.masterSchedule;
    if ~ismember('StimulusID', M.Properties.VariableNames)
        return;
    end

    condition  = rowString(r, 'Condition', "");
    wavPath    = rowString(r, 'WavPath', "");
    taskType   = rowString(r, 'TaskType', "");
    isPractice = rowLogical(r, 'IsPractice', false);
    block      = rowDouble(r, 'Block', NaN);
    trialIndex = rowDouble(r, 'TrialIndex', NaN);

    hit = strcmp(string(M.Condition), condition) & ...
          (logical(M.IsPractice) == logical(isPractice)) & ...
          (double(M.Block) == double(block)) & (double(M.TrialIndex) == double(trialIndex));

    if ismember('WavPath', M.Properties.VariableNames) && strlength(wavPath) > 0
        hit = hit & strcmp(string(M.WavPath), wavPath);
    end
    if ismember('TaskType', M.Properties.VariableNames) && strlength(taskType) > 0
        hit = hit & strcmp(string(M.TaskType), taskType);
    end

    idx = find(hit, 1, 'first');
    if ~isempty(idx)
        stimID = double(M.StimulusID(idx));
    end
end
