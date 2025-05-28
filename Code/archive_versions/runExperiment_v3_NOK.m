% runExperiment.m
function runExperiment()
    %% 0) Clean start
    clearvars; clc;
        PsychPortAudio('Close')
    PsychDefaultSetup(2);
    Screen('Preference','SkipSyncTests',1);
    InitializePsychSound(1);
    rng('shuffle');

    %% 1) Subject ID + file paths
    subjID = input('Zadejte ID participanta (řetězec): ','s');
%     mainDir    = fileparts(mfilename('fullpath'));
    mainDir    = fileparts(pwd);
    pngDir     = fullfile(mainDir,'PNG');
    stimDirImp = fullfile(mainDir,'Stimuli','Imp');   
    stimDirImpSubs = fullfile(mainDir,'Stimuli','Imp','Subset Imp - wav_norm'); 
    stimDirImpPrac = fullfile(mainDir,'Stimuli','Imp','Practice - wav_norm'); 
    stimDir = fullfile(mainDir,'Stimuli');
    resultsDir = fullfile(mainDir,'Results');
    if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
    dataFile   = fullfile(resultsDir, sprintf('subject_%s.mat', subjID));

    %% 2) Resume or restart?
    if exist(dataFile,'file')
        load(dataFile,'params','resultsTable');
        resp = input('Výsledky existují. Pokračovat [C] nebo Restart [R]? ','s');
        if upper(resp)=='R'
            delete(dataFile);
            resume = false;
        else
            resume = true;
        end
    else
        resume = false;
    end

    %% 3) Build params (and sequences if not resume)
    params = struct();
    params.subjID       = subjID;
    params.mainDir      = mainDir;
    params.pngDir       = pngDir;
    params.stimDirImp   = stimDirImp;
    params.stimDir   = stimDir;
    params.dataFile     = dataFile;
    params.debugClickable = false;

    if ~resume
        % 3a) Practice trials (4)
        prac = dir(fullfile(stimDirImpPrac,'*.wav'));
        pracNames = {prac.name}';
        pracNames = pracNames(randperm(4));
        pracTask  = repmat({'num';'type'},2,1);
        pracTask  = pracTask(randperm(4));
        params.pracTrials = table(pracNames, pracTask, (1:4)', ...
            'VariableNames',{'wavFile','taskType','trialIndex'});

        % 3b) Experimental trials (40 in two blocks)
        subImp = dir(fullfile(stimDirImpSubs,'*.wav'));
        names  = {subImp.name}';
        names  = names(randperm(40));
        tasks  = [repmat("num",20,1); repmat("type",20,1)];
        tasks  = tasks(randperm(40));
        trialIdx = [ (1:20)'; (1:20)' ];
        block    = [ ones(20,1); 2*ones(20,1) ];
        params.expTrials = table(names, tasks, trialIdx, block, ...
            'VariableNames',{'wavFile','taskType','trialIndex','block'});

        % 3c) Empty resultsTable
%         params.resultsTable = table( ...
%             string(), false(([])), string(), string(), ...
%             double([]), double([]), string(), double([]), ...
%             double([]), double([]), datetime(), ...
%             'VariableNames',{'subjID','isPractice','wavFile','taskType', ...
%                              'trialIndex','block','resp','rtTask', ...
%                              'loadRating','rtLoad','time'});
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

    %% 4) Open Screen & Audio once
    screenN = max(Screen('Screens'));
    [win, winRect] = PsychImaging('OpenWindow',screenN,0);
    Screen('TextSize',win,24);
    HideCursor; Priority(MaxPriority(win));
    params.win     = win;
    params.winRect = winRect;

    sr = 44100; channels = 2;
    pah = PsychPortAudio('Open', [], 1, 0, sr, channels);
    params.pahandle   = pah;
    params.samplerate = sr;

%     % warm-up audio
%     PsychPortAudio('Start', pah, 0, 0, 1);
%     PsychPortAudio('Stop',  pah);

    %% 5) Main Flow
    try
        showWelcomeScreen(params);
        testVolumeTask(params);
        % runImpCondition returns updated resultsTable in params
        params.debugClickable = true;
        params = runImpCondition(params);
        % final save
        safeSave(params);

    catch ME
        safeSave(params);
        sca; Priority(0); ShowCursor;
        rethrow(ME);
    end

    %% 6) Tear-down
    sca; ShowCursor; Priority(0);
    PsychPortAudio('Close', pah);
    fprintf('Konec experimentu. Data v: %s\n', dataFile);
end


% ----------------------- safeSave util ------------------------------
function safeSave(params)
    try
        resultsTable = params.resultsTable; %#ok<NASGU>
        save(params.dataFile,'params','resultsTable','-v7');
    catch ex
        warning('Chyba při ukládání: %s', ex.message);
    end
end
