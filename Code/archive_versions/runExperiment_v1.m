% function runExperiment()
    %% 1) Inicializace a nastavení cest
    clearvars; clc;

    % Nastavím hlavní složky
    paths.main    = fileparts(pwd); % Kořenová složka
    paths.stimuli = fullfile(paths.main, 'Stimuli/Imp/');  % Složka s .wav
    paths.results = fullfile(paths.main, 'Results');  % Zde budeme ukládat data
    if ~exist(paths.results, 'dir')
        mkdir(paths.results);
    end

    % Inicializace Psychtoolboxu
    PsychDefaultSetup(2);          % dělá standardní nastavení (screen, atd.)
    rng('shuffle');                % promíchá seed pro randomizaci
    InitializePsychSound(1);       % zkusí low-latency mode (1), jinak 0

    %% 2) Zadání ID participanta a příprava logování
    subjID = input('Zadejte ID participanta (číslo): ');
    fprintf('Spouštíme experiment pro subjekt: %d\n', subjID);

    % Vytvoříme strukturu, kam budeme ukládat výsledky
    results.subjID   = subjID;
    results.datetime = datestr(now);
    results.log = [];  % sem se budou ukládat jednotlivé trialy

    % Cesta k výstupnímu .mat souboru
    outFile = fullfile(paths.results, sprintf('subject_%03d.mat', subjID));

    % Pokud existuje starý soubor, můžeme ho načíst (kdybychom chtěli navázat)
    if exist(outFile, 'file')
        load(outFile, 'results');
        fprintf('Načítám existující soubor s daty. Pokračuji.\n');
    end

    %% 3) Definice (načtení) seznamu stimulů
    % Jako ukázku – vyhledáme všechny .wav v jedné podsložce, např. "Stimuli\Volume test"
    % (samozřejmě si to přizpůsobte).
    stimFolder = fullfile(paths.main, '/Stimuli/Volume test_norm');
    stimFiles  = dir(fullfile(stimFolder, '*.wav'));
    stimNames  = {stimFiles.name};

    % Pokud se jedná o reálný experiment s mnoha soubory, radši bychom měli CSV s tabulkou
    % (název, emoce, atd.), kterou načteme, a pak randomizujeme jen pořadí. Tady jen ukázka:
    nTrials = length(stimNames);

    % Pro randomizaci (pouze ukázka, v reálu by se řešilo i counterbalancing atd.)
    idxRand = randperm(nTrials);
    stimNames = stimNames(idxRand);

    %% 4) Nastavení obrazovky
    try
        screenNumber = max(Screen('Screens')); % vybere hlavní displej
        [win, winRect] = PsychImaging('OpenWindow', screenNumber, 0); % 0 = černé pozadí
        Screen('TextSize', win, 24);

        HideCursor;
        Priority(MaxPriority(win));

        % Pro prezentaci (snímkovací frekvenci)
        ifi = Screen('GetFlipInterval', win);

        %% 5) Průchod jednotlivými trialy
        for t = 1:nTrials

            % 5a) Kontrola, jestli už jsme náhodou tento trial neodjeli (obnovený experiment)
            %     Třeba v results.log už může být nějaký počet hotových trialů
            if isfield(results, 'log') && length(results.log) >= t
                fprintf('Trial %d už je uložen, přeskakuji.\n', t);
                continue; 
            end

            %% 5b) Zobrazení fixace / uvítacího textu atd. (dle potřeby)
            DrawFormattedText(win, sprintf('Trial %d/%d\nFixation cross', t, nTrials), 'center', 'center', [255 255 255]);
            Screen('Flip', win);
            WaitSecs(1.0); % třeba 1 sekunda fixace

            %% 5c) Přehrání zvuku
            thisStim = fullfile(stimFolder, stimNames{t});
            pahandle = PsychPortAudio('Open', [], [], 0, [], 2); % stereo = 2 kanály
            [y, freq] = audioread(thisStim);
            PsychPortAudio('FillBuffer', pahandle, [y']);
            PsychPortAudio('Start', pahandle, 1);

            % Počkáme, až se zvuk dohraje
            stimDuration = length(y) / freq;
            WaitSecs(stimDuration);

            % Zavřeme audio
            PsychPortAudio('Close', pahandle);

            %% 5d) Sběr odpovědi
            %  -- Tady je čistě ukázka: vyvoláme text s pokynem k ratingu
            answer = presentRatingScreen(win, t, nTrials);
            rt = answer.rt;
            userResp = answer.userResp;

            %% 5e) Uložení výsledku do results
            trialInfo.trialN    = t;
            trialInfo.stimFile  = stimNames{t};
            trialInfo.resp      = userResp;
            trialInfo.rt        = rt;
            trialInfo.timeStamp = datestr(now);

            results.log = [results.log; trialInfo]; %#ok<AGROW> 
            
            % 5f) Průběžné uložení do souboru .mat (důležité pro "recovery" v případě crash)
            save(outFile, 'results');

            % 5g) Tady bychom mohli vložit check pro stisk klávesy ESC k přerušení
            [keyIsDown,~,keyCode] = KbCheck;
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    disp('Experiment rušen uživatelem. Ukládám a končím.');
                    break;
                end
            end

        end % Konec for-cyklu

        %% 6) Dokončení experimentu
        DrawFormattedText(win, 'Konec experimentu. Děkujeme!', 'center', 'center', [255 255 255]);
        Screen('Flip', win);
        WaitSecs(2);

        sca; % zavře okno (Screen)
        Priority(0);
        ShowCursor;

        disp('Experiment ukončen úspěšně.');
        disp(['Data uložená v: ' outFile]);

    catch ME
        % Pokud něco spadne, chceme data uložit a psychtoolbox korektně ukončit
        sca;
        Priority(0);
        ShowCursor;

        save(outFile, 'results');
        disp('Došlo k chybě, data byla uložena. Přeposílám error:');
        rethrow(ME);
    end
% end


%% POMOCNÁ FUNKCE PRO RATING
function answer = presentRatingScreen(win, t, nTrials)
    % Jednoduchá ukázka, zobrazím text a čekám na klávesu
    % (v reálném experimentu byste měli připravenou
    %  vlastní funkci pro vizuální stupnice, myš atd.)

    startTime = Screen('Flip', win);
    DrawFormattedText(win, sprintf('Trial %d/%d\nStiskni [1] nebo [2]', t, nTrials), 'center', 'center', [255 255 255]);
    Screen('Flip', win);

    resp = [];
    while isempty(resp)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('1!'))
                resp = 1;
            elseif keyCode(KbName('2@'))
                resp = 2;
            end
        end
    end

    rt = secs - startTime;

    answer.userResp = resp;
    answer.rt       = rt;
end
