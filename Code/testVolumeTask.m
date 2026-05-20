function testVolumeTask(params)
% testVolumeTask  –  Volume‐check screen with Play & Continue buttons,
%                   controlled by mouse OR gamepad (Debug‐rect support).

    %% 1) Paths
    pngPath = fullfile(params.pngDir, 'vol_test.png');
    testWav = fullfile(params.stimVolTest, '02 Piste 2.wav');
    assert(exist(pngPath,'file')==2,  'PNG not found: %s', pngPath);
    assert(exist(testWav,'file')==2, 'WAV not found: %s', testWav);

    %% 2) Load PNG & make texture
    img   = imread(pngPath);
    [imgH,imgW,~] = size(img);
    tex   = Screen('MakeTexture',params.win,img);

    %% 3) Letterbox compute
    scrR  = params.winRect; scrW = scrR(3)-scrR(1); scrH = scrR(4)-scrR(2);
    aspectImg = imgW/imgH; aspectScr = scrW/scrH;
    if aspectScr>aspectImg
        outH = scrH; outW = round(outH*aspectImg);
    else
        outW = scrW; outH = round(outW/aspectImg);
    end
    left = (scrW-outW)/2; top = (scrH-outH)/2;
    dest = [left, top, left+outW, top+outH];

    %% 4) Define buttons in IMAGE coords (adjust to your PNG)
    imgPlay     = [1600 1200 1920 1500];
    imgContinue = [1210 1900 2230 2200];

    %% 5) Scale to SCREEN coords
    scrPlay     = scaleRect(imgPlay,     imgW,imgH,outW,outH,left,top);
    scrContinue = scaleRect(imgContinue, imgW,imgH,outW,outH,left,top);

    %% 6) Load WAV into buffer
    [y,sr] = audioread(testWav);
    if sr~=params.samplerate
        y = resample(y, params.samplerate, sr);
    end
    if size(y,2)==1, y = repmat(y,1,2); end
    y = y';  % channels×samples

    %% 7) Initialize selection & joystick state
    selection = 1;    % 1=Play, 2=Continue
    prevH     = 0;
    ShowCursor('Arrow', params.win);

    %% 8) Main loop
    if isAutoPilot(params)
        Screen('DrawTexture',params.win,tex,[],dest);
        Screen('FrameRect',params.win,[50 200 255],scrPlay,5);
        Screen('Flip',params.win);
        PsychPortAudio('FillBuffer', params.pahandle, y);
        PsychPortAudio('Start',      params.pahandle, 1, 0, 1);
        PsychPortAudio('Stop',       params.pahandle, 1);
        WaitSecs(autoPilotDelay(params));
        Screen('Close', tex);
        HideCursor(params.win);
        return;
    end

    while true
        checkAbort();
        % Draw background
        Screen('DrawTexture',params.win,tex,[],dest);

        % Debug outlines
        if params.debugClickable
            Screen('FrameRect',params.win,[255 0 0],scrPlay,3);
            Screen('FrameRect',params.win,[255 0 0],scrContinue,3);
        end

        % Highlight current selection
        if selection==1
            Screen('FrameRect',params.win,[50 200 255],scrPlay,5);
        else
            Screen('FrameRect',params.win,[50 200 255],scrContinue,5);
        end

        Screen('Flip',params.win);

        % --- Mouse input ---
        [mx,my,mb] = GetMouse(params.win);
        if any(mb)
            if     IsInRect(mx,my,scrPlay)
                % Play
                PsychPortAudio('FillBuffer', params.pahandle, y);
                PsychPortAudio('Start',      params.pahandle, 1, 0, 1);
                PsychPortAudio('Stop',       params.pahandle, 1);
            elseif IsInRect(mx,my,scrContinue)
                % Continue
                % wait release
                [~,~,mb2] = GetMouse(params.win);
                while any(mb2)
                    [~,~,mb2] = GetMouse(params.win);
                    WaitSecs(0.01);
                end
                break;
            end
            % wait release
            [~,~,mb2] = GetMouse(params.win);
            while any(mb2)
                [~,~,mb2] = GetMouse(params.win);
                WaitSecs(0.01);
            end
        end

        % --- Gamepad input ---
        horiz = 0; joyB = [];
        if isfield(params,'joy') && ~isempty(params.joy)
            try
                [axes, buttons] = read(params.joy);
                horiz  = axes(2);
                joyB   = buttons;
            catch
            end
        end

        % Left/Right to toggle selection
        if horiz < -0.5 && prevH >= -0.5
            selection = max(1,selection-1);
        elseif horiz > 0.5 && prevH <= 0.5
            selection = min(2,selection+1);
        end
        prevH = horiz;

        % Confirm with any gamepad button
        if any(joyB)
            if selection==1
                % Play
                PsychPortAudio('FillBuffer', params.pahandle, y);
                PsychPortAudio('Start',      params.pahandle, 1, 0, 1);
                PsychPortAudio('Stop',       params.pahandle, 1);
            else
                % Continue
                % wait release
                % wait until all gamepad buttons are released
                while true
                    [~, buttons] = read(params.joy);   % second output is the button vector
                    if ~any(buttons)
                        break;
                    end
                    WaitSecs(0.01);
                end
                break;
            end
        end

        % ESC to abort
        [kd,~,kc] = KbCheck;
        if kd && kc(KbName('ESCAPE'))
            sca; error('Aborted by user (ESC).');
        end

        WaitSecs(0.01);
    end

    %% 9) Cleanup
    HideCursor(params.win);
    Screen('Close', tex);
end
