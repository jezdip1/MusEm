function testVolumeTask(params)
% testVolumeTask  –  Obrazovka pro nastavení hlasitosti se dvěma tlačítky.
%   - PNG: instrukce + tlačítko „Přehrát“ a „Pokračovat“.
%   - Klik na „Přehrát“ přehraje testovací WAV (lze opakovaně).
%   - Klik na „Pokračovat“ ukončí funkci.
%
%   Volání např.  testVolumeTask(params);

    %% ----- 1) Cesty k souborům  ---------------------------------------
    pngPath  = fullfile(params.pngDir,  'vol_test.png');           % obrázek s 2 tlačítky
    testWav  = fullfile(params.stimVolTest, '02 Piste 2.wav');
    assert(exist(pngPath,'file')==2,  'PNG nenalezen: %s', pngPath);
    assert(exist(testWav,'file')==2, 'WAV nenalezen: %s', testWav);

    %% ----- 2) Načti obrázek + vytvoř texturu --------------------------
    img = imread(pngPath);
    [imgH, imgW, ~] = size(img);
    tex = Screen('MakeTexture', params.win, img);

    %% ----- 3) Jak se obrázek skaluje na aktuální monitor  ------------
    scrRect  = params.winRect;
    scrW     = scrRect(3) - scrRect(1);
    scrH     = scrRect(4) - scrRect(2);
    aspectImg = imgW / imgH;
    aspectScr = scrW  / scrH;

    if aspectScr > aspectImg        % monitor je „širší“  → plná výška
        outH = scrH;
        outW = round(outH * aspectImg);
    else                            % jinak plná šířka
        outW = scrW;
        outH = round(outW / aspectImg);
    end
    left   = (scrW - outW)/2;
    top    = (scrH - outH)/2;
    destRect = [left, top, left+outW, top+outH];

    %% ----- 4) Souřadnice tlačítek v IMG a převod na SCREEN -----------
    % >>> DOPLŇTE PODLE SVÉHO PNG! <<<
    % imgPlayRect      = [x1 y1 x2 y2];   % např. [350 650 650 720]
    % imgContinueRect  = [x1 y1 x2 y2];   % např. [750 650 1050 720]
    imgPlayRect     = [1600 1200 1920 1500];     % <-- vzorové hodnoty
    imgContinueRect = [1210 1900 2230 2200];    % <-- vzorové hodnoty

    scaleX = outW / imgW;
    scaleY = outH / imgH;

    scrPlayRect = [ ...
        imgPlayRect(1)*scaleX + left,  imgPlayRect(2)*scaleY + top, ...
        imgPlayRect(3)*scaleX + left,  imgPlayRect(4)*scaleY + top ];

    scrContinueRect = [ ...
        imgContinueRect(1)*scaleX + left,  imgContinueRect(2)*scaleY + top, ...
        imgContinueRect(3)*scaleX + left,  imgContinueRect(4)*scaleY + top ];

%%
% % ---- po výpočtu scrPlayRect a scrContinueRect -----------------
% if ~isfield(params,'debugClickable'), params.debugClickable = false; end
% 
% % před hlavní smyčkou vykreslování
% Screen('DrawTexture', params.win, tex, [], destRect);
% 
% if params.debugClickable
%     % 1) povol alfa–blending (udělá se jednou, třeba hned po otevření okna)
%     Screen('BlendFunction', params.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% 
%     % 2) nakresli poloprůhledné červené rámečky (alpha = 100/255 ≈ 40 %)
%     translucentRed = [255 0 0 100];
% 
%     Screen('FillRect', params.win, translucentRed, scrPlayRect);
%     Screen('FillRect', params.win, translucentRed, scrContinueRect);
% end
% 
% Screen('Flip', params.win);

    %% ----- 5) Připrav WAV do paměti (kvůli rychlosti) -----------------
    [y, sr] = audioread(testWav);

    % open-device SR ≈  sr?  (params.pahandle se otevíral s wavFreq)
    if sr ~= params.samplerate
        y = resample(y, params.samplerate, sr);
    end
    if size(y,2)==1                       % mono → stereo
        y = repmat(y,1,2);
    end
    y = y';                               % [channels × samples]

    %% ----- 6) Hlavní smyčka – čekáme na kliky -------------------------
    ShowCursor('Arrow', params.win);
        % vykresli PNG
        Screen('DrawTexture', params.win, tex, [], destRect);
        Screen('Flip', params.win);
    % ---- po výpočtu scrPlayRect a scrContinueRect -----------------
    if ~isfield(params,'debugClickable'), params.debugClickable = false; end

    % před hlavní smyčkou vykreslování
    Screen('DrawTexture', params.win, tex, [], destRect);

    if params.debugClickable
        % 1) povol alfa–blending (udělá se jednou, třeba hned po otevření okna)
        Screen('BlendFunction', params.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        % 2) nakresli poloprůhledné červené rámečky (alpha = 100/255 ≈ 40 %)
        translucentRed = [255 0 0 10];

        Screen('FillRect', params.win, translucentRed, scrPlayRect);
        Screen('FillRect', params.win, translucentRed, scrContinueRect);
    end

    Screen('Flip', params.win);
    running = true;
    while running
%         % vykresli PNG
%         Screen('DrawTexture', params.win, tex, [], destRect);
%         Screen('Flip', params.win);
%     % ---- po výpočtu scrPlayRect a scrContinueRect -----------------
%     if ~isfield(params,'debugClickable'), params.debugClickable = false; end
% 
%     % před hlavní smyčkou vykreslování
%     Screen('DrawTexture', params.win, tex, [], destRect);
% 
%     if params.debugClickable
%         % 1) povol alfa–blending (udělá se jednou, třeba hned po otevření okna)
%         Screen('BlendFunction', params.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% 
%         % 2) nakresli poloprůhledné červené rámečky (alpha = 100/255 ≈ 40 %)
%         translucentRed = [255 0 0 100];
% 
%         Screen('FillRect', params.win, translucentRed, scrPlayRect);
%         Screen('FillRect', params.win, translucentRed, scrContinueRect);
%     end
% 
%     Screen('Flip', params.win);
        % kontrola myši
        [mx,my,buttons] = GetMouse(params.win);
        if any(buttons)
            if IsInRect(mx,my, scrPlayRect)
                % ---------- PŘEHRÁT ZVUK ----------
                PsychPortAudio('FillBuffer', params.pahandle, y);
                PsychPortAudio('Start',      params.pahandle, 1, 0, 1);
                PsychPortAudio('Stop',       params.pahandle, 1); % počká
            elseif IsInRect(mx,my, scrContinueRect)
                % ---------- POKRAČOVAT ----------
                running = false;
            end
            % počkej, až se tlačítko uvolní, ať se nerozjede double-click
            while any(buttons)
                [~,~,buttons] = GetMouse(params.win);
                WaitSecs(0.01);
            end
        end

        % možnost přerušit ESC
        [kd,~,kc] = KbCheck;
        if kd && kc(KbName('ESCAPE'))
            sca; ShowCursor;
            error('Experiment přerušen uživatelem (ESC).');
        end
        WaitSecs(0.01);
    end

    HideCursor(params.win);
    Screen('Close', tex);
end
