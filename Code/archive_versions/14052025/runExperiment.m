%% runExperiment.m
% Main controller for the MusEm Imp condition experiment
% - Configurable number of practice and experimental trials
% - Resume or restart based on existing data
% - Generates tables with full wav paths

function runExperiment()
    %% 0) Clear and setup
    clearvars; clc;
       PsychPortAudio('Close')
    PsychDefaultSetup(2);
    Screen('Preference','SkipSyncTests',1);
    InitializePsychSound(1);
    rng('shuffle');

    %% 1) Subject ID and paths
    params.subjID     = input('Zadejte ID participanta (řetězec): ', 's');
    baseDir    = fileparts(pwd); % Kořenová složka
    params.pngDir     = fullfile(baseDir, 'PNG');
    params.stimDir = fullfile(baseDir, 'Stimuli');
    params.stimDirImp = fullfile(baseDir, 'Stimuli', 'Imp');
    params.stimDirAffect = fullfile(baseDir, 'Stimuli', 'Affect_Em');
    params.resultsDir = fullfile(baseDir, 'Results');
    if ~exist(params.resultsDir, 'dir'); mkdir(params.resultsDir); end
    params.dataFile   = fullfile(params.resultsDir, sprintf('subject_%s.mat', params.subjID));

    %% 2) Number of trials (configurable)
    params.nPractice  = 0;    % number of practice trials 4
    params.nPerBlock  = 2;   % trials per experimental block 20
    params.nBlocks    = 2;    % number of experimental blocks 2
    params.nExpTotal  = params.nPerBlock * params.nBlocks;

    %% 3) Resume or restart
    if exist(params.dataFile, 'file')
        tmp = load(params.dataFile, 'params');
        oldParams = tmp.params; clear tmp;
        resp = input('Výsledky existují. Pokračovat [C] nebo Restart [R]? ','s');
        if upper(resp)=='C'
            params = oldParams;
%             params.resultsTable = load(params.dataFile, 'resultsTable').resultsTable;
            resume = true;
        else
            delete(params.dataFile);
            resume = false;
        end
    else
        resume = false;
    end

    %% 4) Generate trial order if not resuming
    if ~resume
        % Practice trials
        pracDir = fullfile(params.stimDirImp, 'Practice - wav_norm');
        pracFiles = dir(fullfile(pracDir, '*.wav'));
        pracNames = {pracFiles.name}';
        pracNames = pracNames(randperm(numel(pracNames)));
        pracNames = pracNames(1:params.nPractice);
        % Assign tasks alternately and shuffle
        pracTasks = repmat({'num';'type'}, ceil(params.nPractice/2), 1);
        pracTasks = pracTasks(1:params.nPractice);
        pracTasks = pracTasks(randperm(params.nPractice));
        % Build table with full paths
        pracPaths = fullfile(pracDir, pracNames);
        params.pracTrials = table(pracPaths, pracTasks, (1:params.nPractice)', ...
            'VariableNames', {'wavPath','taskType','trialIndex'});

        % Experimental trials
        expDir = fullfile(params.stimDirImp, 'Subset Imp - wav_norm');
        expFiles = dir(fullfile(expDir, '*.wav'));
        expNames = {expFiles.name}';
        expNames = expNames(randperm(numel(expNames)));
        expNames = expNames(1:params.nExpTotal);
        expTasks = [repmat("num", params.nExpTotal/2, 1); repmat("type", params.nExpTotal/2, 1)];
        expTasks = expTasks(randperm(params.nExpTotal));
        blocks = repelem((1:params.nBlocks)', params.nPerBlock);
        trialIdx = repmat((1:params.nPerBlock)', params.nBlocks, 1);
        expPaths = fullfile(expDir, expNames);
        params.expTrials = table(expPaths, expTasks, trialIdx, blocks, ...
            'VariableNames', {'wavPath','taskType','trialIndex','block'});

        % Initialize empty results table

            varNames = {'subjID','isPractice','wavFile','taskType', ...
                        'trialIndex','block','resp','rtTask', ...
                        'loadRating','rtLoad','time'};
            varTypes = {'string','logical','string','string', ...
                        'double','double','string','double', ...
                        'double','double','datetime'};

            params.resultsTable = table( ...
                'Size',[0,numel(varNames)], ...
                'VariableTypes',varTypes, ...
                'VariableNames',varNames);
    end

    %% 5) Open screen & audio
    screenN = max(Screen('Screens'));
    [params.win, params.winRect] = PsychImaging('OpenWindow', screenN, 0);
    Screen('TextSize', params.win, 24);
    Priority(MaxPriority(params.win));

    sr = 44100; nch = 2;
    params.pahandle = PsychPortAudio('Open', [], 1, 0, sr, nch);
    params.samplerate = sr;
%     PsychPortAudio('Start', params.pahandle, 0, 0, 1);
%     PsychPortAudio('Stop',  params.pahandle);

    %% 6) Run flow
    try
       ShowCursor;
       params.debugClickable=true;
        showWelcomeScreen(params);
%         testVolumeTask(params);
%         params = runImpCondition(params);
%         params = runAffectCondition(params);
        params = runEmCondition(params);
        safeSave(params);
    catch ME
        safeSave(params);
        sca; Priority(0); ShowCursor;
        rethrow(ME);
    end

    %% 7) Tear-down
    sca; ShowCursor; Priority(0);
    PsychPortAudio('Close', params.pahandle);
    fprintf('Experiment finished. Data saved to %s\n', params.dataFile);
end


%% safeSave
function safeSave(params)
    try
        resultsTable = params.resultsTable; 
        save(params.dataFile, 'params','resultsTable','-v7');
    catch ex
        warning('save failed: %s', ex.message);
    end
end


