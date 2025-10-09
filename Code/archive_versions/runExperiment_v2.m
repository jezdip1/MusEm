function runExperiment()
    % ===========================================
    % runExperiment.m
    % Hlavní řídicí skript, který:
    %  - Vyžádá ID participanta
    %  - Nastaví cesty, inicializuje screen a audio
    %  - Případně nastaví paralelní port (triggery)
    %  - Volá sub-tasky (např. test hlasitosti)
    % ===========================================

    % 1) Vymazání workspace a požádání o ID
    clearvars; clc;
    PsychPortAudio('Close')
    subjID = input('Zadejte ID participanta (libovolný kód): ', 's');
    fprintf('Experiment spouštíme pro participant ID = %s\n', subjID);
    % 2) Definice cest, výstupní složky, atd.
    params = struct(); % Vytvoření prázdné struktury, do které budeme ukládat vše důležité
    params.subjID  = subjID;
    params.mainDir    = fileparts(pwd); % Kořenová složka
%     params.mainDir = fileparts(mfilename('fullpath')); 
    params.dataDir = fullfile(params.mainDir, 'Results');
    params.stimDir = fullfile(params.mainDir, 'Stimuli');
    params.stimDirImp = fullfile(params.mainDir, 'Stimuli/Imp');
    params.pngDir  = fullfile(params.mainDir, 'PNG');
    if ~exist(params.dataDir, 'dir')
        mkdir(params.dataDir);
    end
    outFile = fullfile(params.dataDir, sprintf('subject_%s.mat', subjID));
    params.dataFile = outFile;           % <<— uložit cestu i do params

    % 3) Nastavení random seed, psychtoolbox routine
    rng('shuffle');
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1); % Možná jen pro testování
    
    % 4) Inicializace paralelního portu (pokud ho používáte)
    %    Tady jen ukázka – v praxi záleží, jestli používáte IO64, atd.
    % try
    %    config_io;
    %    params.ioObj = io64;
    %    params.address = hex2dec('0378'); % example address
    %    fprintf('Paralelní port inicializován.\n');
    % catch
    %    warning('Nepodařilo se inicializovat paralelní port.');
    %    params.ioObj = [];
    %    params.address = [];
    % end

    % 5) Otevření screen
    params.screenNumber = max(Screen('Screens'));
    [params.win, params.winRect] = PsychImaging('OpenWindow', params.screenNumber, 0); 
    Screen('TextSize', params.win, 24);
    HideCursor;
    Priority(MaxPriority(params.win));

    % 6) Inicializace audio – otevřeme 1x a budeme používat jediné audio zařízení
    InitializePsychSound(1); 
    % Vytvoříme audio handle. Například 2 kanály (stereo) a latence = 0.
    % Pokud nepotřebujete mikrofon, deviceID může být [].
    % freq = 44100; (nebo co odpovídá vašim WAV)
    % buffersize = 512; (příklad)
    % --- v runExperiment, hned po InitializePsychSound(1) -------------
    wavFreq = 44100;                      %  = SR vašich souborů (.wav)
    nChan   = 2;                          %  stereo

 
    try
        params.pahandle   = PsychPortAudio('Open', [], 1, 0, wavFreq, nChan);
        params.samplerate = wavFreq;      
%     params.pahandle = PsychPortAudio('Open', [], 1, 0, [], 2);
%         params.pahandle = PsychPortAudio('Open', [], [], 0, [], 2); % stereo = 2 kanály

        % 1+8 = kód pro playback + allow volume setting
        % freq a buffer lze doplnit, pokud nutné
%         PsychPortAudio('Start', params.pahandle, 0, 0, 1); 
        % "start" se 0 opakováními, aby to čekalo na FillBuffer, je to takový "warm-up"
        fprintf('Audio device bylo otevřeno.\n');
    catch
        sca;
        error('Nepodařilo se otevřít audio device. Konec.');
    end

    showWelcomeScreen(params);
    params.debugClickable = true;   % červené / zelené rámečky ON
    testVolumeTask(params);
    params.debugClickable = true;   % červené / zelené rámečky ON
    runImpCondition(params);
    % --- Zde by následovaly další sub-tasky, např. runImpCondition(params), runAffectCondition(params), atd. ---
    % runImpCondition(params);
    % runAffectCondition(params);
    % runEmCondition(params);

    % 8) Uklizení a ukončení experimentu
    sca; 
    Priority(0);
    ShowCursor;
    
    % Zavřeme audio handle
    if isfield(params, 'pahandle')
        PsychPortAudio('Close', params.pahandle);
    end
    
    fprintf('Experiment dokončen. Díky!\n');
end
