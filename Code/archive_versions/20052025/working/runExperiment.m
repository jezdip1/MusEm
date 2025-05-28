function runExperiment()
    %% 0) Startup
    clearvars; clc;
     PsychPortAudio('Close')
    PsychDefaultSetup(2);
    Screen('Preference','SkipSyncTests',1);
    InitializePsychSound(1);
    rng('shuffle');
    
    % Try to open joystick #1
    if exist('vrjoystick','file')
        try
            params.joy = vrjoystick(1);
            fprintf('Gamepad detected: using joystick #1.\n');
        catch
            params.joy = [];
            warning('vrjoystick found but failed to open. No gamepad input.');
        end
    else
        params.joy = [];
        warning('vrjoystick function not found. Gamepad disabled.');
    end

    %% 1) Subject + Paths + Resume
    params.subjID       = input('Zadejte ID participanta: ','s');
    baseDir    = fileparts(pwd);
    params.pngDir       = fullfile(baseDir,'PNG');
    % Single place for all stimulus directories
    params.stimDirImp   = fullfile(baseDir,'Stimuli','Imp');
    params.stimDirAffect= fullfile(baseDir,'Stimuli','Affect_Em');
    params.stimDirEm    = fullfile(baseDir,'Stimuli','Affect_Em');
    params.stimVolTest    = fullfile(baseDir,'Stimuli','Volume test');
    resultsDir          = fullfile(baseDir,'Results');
    if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
    params.dataFile     = fullfile(resultsDir, sprintf('subject_%s.mat',params.subjID));

%     % Trial counts (configurable)
%     params.nPracticeImp   = 4;
%     params.nPracticeAffect= 2;
%     params.nPracticeEm    = 2;
%     params.nPerBlock      = 20;
%     params.nBlocks        = 2;

     % Trial counts (configurable)
    params.nPracticeImp   = 4;
    params.nPracticeAffect= 2;
    params.nPracticeEm    = 2;
    params.nPerBlock      = 5;
    params.nBlocks        = 2;   
    
    resume = false;
    %% Resume vs. fresh start
    wantResume=0;
    if exist(params.dataFile,'file')
        data = load(params.dataFile);
        if isfield(data,'params')
            if isfield(data.params,'masterSchedule')
                 if isfield(data.params,'resultsTable')
                     wantResume=1;
                 end
            end
        end
%         wantResume = isfield(data,'params') ...
%                   && isfield(data,'masterSchedule') ...
%                   && isfield(data,'resultsTable');
        if wantResume
            choice = input('Výsledky existují. Pokračovat [C] nebo Restart [R]? ','s');
            if upper(choice)=='C'
                % pick up where we left off
                params             = data.params;
%                 params.masterSchedule = data.masterSchedule;
%                 params.resultsTable   = data.resultsTable;
                resume = true;
            else
                % start clean
                delete(params.dataFile);
                resume = false;
            end
        else
            warning('Soubor %s nemá všechny potřebné proměnné. Začínám znovu.', params.dataFile);
            delete(params.dataFile);
            resume = false;
        end
    else
        resume = false;
    end


    %% 2) Master schedule

%% ——— Build masterSchedule with subset & order C‐B ———————————
if ~resume
    % compute parity
    idNum    = str2double(params.subjID);
    isOddID  = mod(idNum,2)==1;
    subsetA  = isOddID * 1 + ~isOddID * 2;   % odd→1 for Affect, even→2
    subsetE  = isOddID * 2 + ~isOddID * 1;   % odd→2 for Em,    even→1
    
    % condition order: mod4 in [0,1] → Affect first, else Em first
    m4       = mod(idNum,4);
    affectFirst = (m4==0 || m4==1);
    
    masterCols    = {'Condition','IsPractice','WavPath','TaskType','TrialIndex','Block'};
    masterVarTypes= {'string','logical','string','string','double','double'};
    master        = table('Size',[0 numel(masterCols)], ...
                          'VariableTypes',masterVarTypes, ...
                          'VariableNames',masterCols);
    
    %  Imp always first
    master = [master; buildSchedule('Imp',     params.stimDirImp,    params.nPracticeImp, params.nPerBlock, params.nBlocks, 1)];
    
    %  Now Affect & Em in counterbalanced order
    if affectFirst
        master = [master; buildSchedule('Affect', params.stimDirAffect, params.nPracticeAffect, params.nPerBlock, params.nBlocks, subsetA)];
        master = [master; buildSchedule('Em',     params.stimDirEm,     params.nPracticeEm,     params.nPerBlock, params.nBlocks, subsetE)];
    else
        master = [master; buildSchedule('Em',     params.stimDirEm,     params.nPracticeEm,     params.nPerBlock, params.nBlocks, subsetE)];
        master = [master; buildSchedule('Affect', params.stimDirAffect, params.nPracticeAffect, params.nPerBlock, params.nBlocks, subsetA)];
    end
    
    params.masterSchedule = master;
end

    %% 3) Unified results table
    if ~resume
        varNames = {'Condition','IsPractice','WavPath','TaskType','TrialIndex','Block',...
                    'Resp','RtTask','LoadRating','RtLoad','Pref','Arousal','Valence','Emotion','RtDim','RtEm','Time'};
        varTypes = {'string','logical','string','string','double','double',...
                    'string','double','double','double','double','double','double','string','double','double','datetime'};
        params.resultsTable = table('Size',[0,numel(varNames)],...
                                   'VariableTypes',varTypes,...
                                   'VariableNames',varNames);
    end

    %% 4) Open window & audio
    [params.win, params.winRect] = PsychImaging('OpenWindow', max(Screen('Screens')), 0);
    Screen('TextSize', params.win, 24);
    HideCursor; Priority(MaxPriority(params.win));
    pah = PsychPortAudio('Open',[],1,0,44100,2);
    params.pahandle   = pah;
    params.samplerate = 44100;
%     PsychPortAudio('Start', pah, 0, 0, 1);
%     PsychPortAudio('Stop',  pah);
%     params.recHandle  = PsychPortAudio('Open', [], 2, 1, params.samplerate, 1);
%     params.recHandle = PsychPortAudio('Open', [], 2, 1, params.samplerate, 1, params.samplerate * 30,0,[],0);
%     params.recHandle = PsychPortAudio('Open', [], 2, 1, sr, 1);
%     PsychPortAudio('GetAudioData', params.recHandle, 0);
    %% 5) Run experiment
    try
        params.debugClickable=false;
%         params.debugClickable=true;
        if ~resume
        showWelcomeScreen(params);
        testVolumeTask(params);
        end
        params=runImpCondition(params);
        params=runAffectCondition(params);
        params=runEmCondition(params);
        safeSave(params);
    catch ME
        safeSave(params);
        sca; Priority(0); ShowCursor;
        rethrow(ME);
    end

    %% 6) Close
    sca; Priority(0); ShowCursor;
    PsychPortAudio('Close', pah);
%     PsychPortAudio('Close', params.recHandle);
    fprintf('Done. Data saved: %s\n', params.dataFile);
end


