function runExperiment()
    %% 0) Startup
    clearvars; clc;
    codeDir = fileparts(mfilename('fullpath'));
    addpath(codeDir, '-begin');
    addpath(fileparts(codeDir), '-begin');
    lab = hammer.config('MusEm', fileparts(codeDir));
    params = struct();
    cleanupObj = onCleanup(@cleanupRuntime); %#ok<NASGU>
    if isfolder(fullfile(codeDir,'ppdev-mex')), addpath(fullfile(codeDir,'ppdev-mex')); end
    try, PsychPortAudio('Close'); catch, end
    try, ppdev_mex('CloseAll'); catch, end

    params.sync = initSyncDevice;
    syncTriggerOff(params.sync);

    PsychDefaultSetup(2);
    Screen('Preference','SkipSyncTests',lab.skipSync);
    params.skipSyncTests = lab.skipSync;
    params.Runtime = lab.Runtime;
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
    envSubjID = getenv('MUSEM_SUBJID');
    if ~isempty(envSubjID)
        params.subjID = char(envSubjID);
        fprintf('Using subject ID from MUSEM_SUBJID: %s\n', params.subjID);
    else
        params.subjID = input('Zadejte ID participanta: ','s');
    end
    params.subjID = hammer.subject(params.subjID);
    params = applyAutoPilotSettings(params);
    baseDir    = fileparts(codeDir);
    params.pngDir       = fullfile(baseDir,'PNG');
    % Single place for all stimulus directories
    params.stimDirImp   = fullfile(lab.stimuli,'Imp');
    params.stimDirAffect= fullfile(lab.stimuli,'Affect_Em');
    params.stimDirEm    = fullfile(lab.stimuli,'Affect_Em');
    params.stimVolTest    = fullfile(lab.stimuli,'Volume test');
    params.resultsDir          = lab.results;
    if ~exist(params.resultsDir,'dir'), mkdir(params.resultsDir); end
    params.dataFile     = fullfile(params.resultsDir, sprintf('%s.mat',params.subjID));

    % Trial counts and timings (configurable)
    % According to the current paradigm notes: Imp has 4 practice trials,
    % Affect/Em have 2 practice trials, each condition has 2 x 20 main trials.
    params.nPracticeImp    = 4;
    params.nPracticeAffect = 2;
    params.nPracticeEm     = 2;
    params.nPerBlock       = 20;
    params.nBlocks         = 2;
    params.fixDuration     = 2.5;
    params.questionDuration= 2.5;

%      % Trial counts (configurable)
%     params.nPracticeImp   = 2;
%     params.nPracticeAffect= 2;
%     params.nPracticeEm    = 2;
%     params.nPerBlock      = 2;
%     params.nBlocks        = 2;   
    
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
            if isAutoPilot(params)
                choice = getenv('MUSEM_AUTOPILOT_RESUME_ACTION');
                if isempty(choice), choice = 'R'; end
                fprintf('Existing results found; autoPilot uses action [%s].\n', upper(strtrim(choice)));
            else
                choice = input('Výsledky existují. Pokračovat [C] nebo Restart [R]? ','s');
            end
            if startsWith(upper(strtrim(choice)),'C')
                % pick up where we left off
                currentSync = params.sync; currentJoy = params.joy;
                params = data.params;
                params.sync = currentSync; params.joy = currentJoy;
                params.Runtime = lab.Runtime;
                params.skipSyncTests = lab.skipSync;
%                 params.masterSchedule = data.masterSchedule;
%                 params.resultsTable   = data.resultsTable;
                resume = true;
            else
                % start clean
                hammer.backupResult(params.dataFile);
                resume = false;
            end
        else
            warning('Soubor %s nemá všechny potřebné proměnné. Začínám znovu.', params.dataFile);
            hammer.backupResult(params.dataFile);
            resume = false;
        end
    else
        resume = false;
    end

    % Re-apply machine-specific paths and add new defaults after resume.
    % This keeps old result files usable even if the project folder was moved.
    params = ensureDefaultParams(params);
    params = applyAutoPilotSettings(params);
    params = configurePaths(params, baseDir);

        % —– Extract numeric ID (or fall back to char‐sum) —–
        tokens = regexp(params.subjID,'(\d+)$','tokens','once');
        if ~isempty(tokens)
            idNum = str2double(tokens{1});
        else
            idNum = sum(double(params.subjID));
        end

        % —– Parity & subset assignment —–
        isOddID  = mod(idNum,2)==1;

        % —– Condition order (Affect vs Em) —–
        m4          = mod(idNum,4);
        affectFirst = (m4==0 || m4==1);

    %% 2) Master schedule

    if ~resume
%         % —– Extract numeric ID (or fall back to char‐sum) —–
%         tokens = regexp(params.subjID,'(\d+)$','tokens','once');
%         if ~isempty(tokens)
%             idNum = str2double(tokens{1});
%         else
%             idNum = sum(double(params.subjID));
%         end
% 
%         % —– Parity & subset assignment —–
%         isOddID  = mod(idNum,2)==1;
        % —– Subset assignment —–
        % Bára's current note uses paired ID groups:
        %   ID 0-1, 4-5, ... -> Affect Subset 1, Em Subset 2
        %   ID 2-3, 6-7, ... -> Affect Subset 2, Em Subset 1
        subsetPairFlip = mod(floor(idNum/2), 2) == 1;
        if subsetPairFlip
            subsetA = 2;
            subsetE = 1;
        else
            subsetA = 1;
            subsetE = 2;
        end

        % —– Condition order (Affect vs Em) —–
        m4          = mod(idNum,4);
        affectFirst = (m4==0 || m4==1);

        % —– Initialize empty master table —–
        masterCols     = {'Condition','IsPractice','WavPath','StimulusID','TaskType','TrialIndex','Block'};
        masterVarTypes = {'string','logical','string','double','string','double','double'};
        master = table( ...
            'Size',          [0,numel(masterCols)], ...
            'VariableTypes', masterVarTypes, ...
            'VariableNames', masterCols);

        % —– Implicit condition always first —–
        master = [ master;
            buildSchedule( ...
                'Imp', params.stimDirImp, ...
                params.nPracticeImp, ...
                params.nPerBlock, params.nBlocks, ...
                1 ) ];

        % —– Then Affect and Em counterbalanced —–
        if affectFirst
            master = [ master;
                buildSchedule( ...
                    'Affect', params.stimDirAffect, ...
                    params.nPracticeAffect, ...
                    params.nPerBlock, params.nBlocks, ...
                    subsetA ) ];
            master = [ master;
                buildSchedule( ...
                    'Em', params.stimDirEm, ...
                    params.nPracticeEm, ...
                    params.nPerBlock, params.nBlocks, ...
                    subsetE ) ];
        else
            master = [ master;
                buildSchedule( ...
                    'Em', params.stimDirEm, ...
                    params.nPracticeEm, ...
                    params.nPerBlock, params.nBlocks, ...
                    subsetE ) ];
            master = [ master;
                buildSchedule( ...
                    'Affect', params.stimDirAffect, ...
                    params.nPracticeAffect, ...
                    params.nPerBlock, params.nBlocks, ...
                    subsetA ) ];
        end

        fprintf('Counterbalancing: id=%g, Affect subset=%d, Em subset=%d, AffectFirst=%d\n', ...
                idNum, subsetA, subsetE, affectFirst);

        % —– Save into params —–
        params.masterSchedule = master;
    end

    %% 3) Unified results table
%     if ~resume
%         varNames = {'Condition','IsPractice','WavPath','TaskType','TrialIndex','Block',...
%                     'Resp','RtTask','LoadRating','RtLoad','Pref','Arousal','Valence','Emotion','RtDim','RtEm','Time'};
%         varTypes = {'string','logical','string','string','double','double',...
%                     'string','double','double','double','double','double','double','string','double','double','datetime'};
%         params.resultsTable = table('Size',[0,numel(varNames)],...
%                                    'VariableTypes',varTypes,...
%                                    'VariableNames',varNames);
%     end
if ~resume
    % add SubjID as first column for easy vertical concatenation later
    varNames = {'SubjID', 'Condition','IsPractice','WavPath','TaskType','TrialIndex','Block',...
                'Resp','RtTask','LoadRating','RtLoad','Pref','Arousal',...
                'Valence','Emotion','RtDim','RtEm','TimeTrialEnd',...
                'ImpPracticeFixBaselineOnset','ImpPracticeSubQuestionNumOnset',...
                'ImpPracticeSubQuestionTypeOnset','ImpPracticePlaySoundOnset',...
                'ImpPracticeStopSoundOnset','ImpPracticeAnsweringNumOnset','ImpPracticeAnsweringTypeOnset',...
                'ImpTrialFixBaselineOnset','ImpTrialSubQuestionNumOnset',...
                'ImpTrialSubQuestionTypeOnset','ImpTrialPlaySoundOnset',...
                'ImpTrialStopSoundOnset','ImpTrialAnsweringNumOnset','ImpTrialAnsweringTypeOnset',...
                'ImpPracticeAnsweringLoadNumOnset','ImpPracticeAnsweringLoadTypeOnset',...
                'ImpTrialAnsweringLoadNumOnset','ImpTrialAnsweringLoadTypeOnset',...  
                'AffPracticeFixBaselineOnset',...
                'AffPracticePlaySoundOnset',...
                'AffPracticeStopSoundOnset',...
                'AffPracticeAnsweringPrefOnset',...
                'AffPracticeAnsweringArousalOnset',... 
                'AffPracticeAnsweringValenceOnset',...                
                'AffTrialFixBaselineOnset',...
                'AffTrialPlaySoundOnset',...
                'AffTrialStopSoundOnset',...
                'AffTrialAnsweringPrefOnset',...
                'AffTrialAnsweringArousalOnset',... 
                'AffTrialAnsweringValenceOnset',...                 
                'EmPracticeFixBaselineOnset',...
                'EmPracticePlaySoundOnset',...
                'EmPracticeStopSoundOnset',...
                'EmPracticeAnsweringPrefOnset',...
                'EmPracticeAnsweringEmotionOnset',...              
                'EmTrialFixBaselineOnset',...
                'EmTrialPlaySoundOnset',...
                'EmTrialStopSoundOnset',...
                'EmTrialAnsweringPrefOnset',...
                'EmTrialAnsweringEmotionOnset'... 
                };
    varTypes = {'string','string','logical','string','string','double','double',...
                'string','double','double','double','double','double',...
                'double','string','double','double','datetime',...
                'datetime','datetime',...
                'datetime','datetime',...
                'datetime','datetime','datetime',...
                'datetime','datetime',...
                'datetime','datetime',...
                'datetime','datetime','datetime',...
                'datetime','datetime',...
                'datetime','datetime',...     
                'datetime',...                   
                'datetime',... 
                'datetime',...                   
                'datetime',... 
                'datetime',...                   
                'datetime',... 
                'datetime',...                   
                'datetime',... 
                'datetime',...                   
                'datetime',... 
                'datetime',...                   
                'datetime',...                
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime',... 
                'datetime'...               
                };

    params.resultsTable = table( ...
        'Size',[0,numel(varNames)], ...
        'VariableTypes',varTypes, ...
        'VariableNames',varNames ...
    );
end

    %% 4) Open window & audio
    [params.win, params.winRect] = PsychImaging('OpenWindow', hammer.screen(lab), 0);
    Screen('TextSize', params.win, 24);
    HideCursor; Priority(MaxPriority(params.win));
%     pah = PsychPortAudio('Open',audioDeviceID,1,0,44100,2);
    pah = PsychPortAudio('Open',lab.audio,1,0,44100,2);   
    params.pahandle   = pah;
    params.samplerate = 44100;

    % ------------------ mic reader init ------------------
    % ALSA‐string you discovered works:
    params.micDeviceName = lab.mic;
    params.audioReader = hammer.microphone(lab);

%     PsychPortAudio('Start', pah, 0, 0, 1);
%     PsychPortAudio('Stop',  pah);
%     params.recHandle  = PsychPortAudio('Open', [], 2, 1, params.samplerate, 1);
%     params.recHandle = PsychPortAudio('Open', [], 2, 1, params.samplerate, 1, params.samplerate * 30,0,[],0);
%     params.recHandle = PsychPortAudio('Open', [], 2, 1, sr, 1);
%     PsychPortAudio('GetAudioData', params.recHandle, 0);
    %% 5) Run experiment
    try
        syncTriggerOff(params.sync);
            WaitSecs(0.5);
        sendSubjectVersion(params)


        params.debugClickable=false;
%         params.debugClickable=true;
        if isAutoPilot(params)
            fprintf('AUTO PILOT MODE: participant responses are synthetic; ESC still aborts.\n');
        end
        if ~resume
            showWelcomeScreen(params);
            testVolumeTask(params);
        end

        % Follow the saved master schedule order exactly. This is important
        % because condition order is counterbalanced by ID mod 4, not by odd/even ID.
        condOrder = unique(params.masterSchedule.Condition, 'stable');
        for ci = 1:numel(condOrder)
            switch char(condOrder(ci))
                case 'Imp'
                    params = runImpCondition(params);
                case 'Affect'
                    params = runAffectCondition(params);
                case 'Em'
                    params = runEmCondition(params);
                otherwise
                    error('Unknown condition in masterSchedule: %s', char(condOrder(ci)));
            end
        end
        safeSave(params);
    catch ME
        safeSave(params);
        try, syncTriggerOff(params.sync); catch, end
        try, release(params.audioReader); catch, end
        try, PsychPortAudio('Stop', params.pahandle); catch, end
        try, PsychPortAudio('Close'); catch, end
        sca; Priority(0); ShowCursor;
        rethrow(ME);
    end

    %% 6) Close
    try, syncTriggerOff(params.sync); catch, end
    try, release(params.audioReader); catch, end
    sca; Priority(0); ShowCursor;
    try, PsychPortAudio('Close', pah); catch, PsychPortAudio('Close'); end
%     PsychPortAudio('Close', params.recHandle);
    fprintf('Done. Data saved: %s\n', params.dataFile);

    function cleanupRuntime()
        % Also runs if schedule, window or microphone initialization fails.
        if isfield(params,'sync')
            try, syncTriggerOff(params.sync); catch, end
            if isfield(params.sync,'serial')
                try, delete(params.sync.serial); catch, end
            end
        end
        if isfield(params,'audioReader'), try, release(params.audioReader); catch, end; end
        if isfield(params,'joy') && ~isempty(params.joy), try, close(params.joy); catch, end; end
        try, PsychPortAudio('Close'); catch, end
        try, Screen('CloseAll'); catch, end
        try, Priority(0); catch, end
        try, ShowCursor; catch, end
        try, ppdev_mex('CloseAll'); catch, end
    end
end


