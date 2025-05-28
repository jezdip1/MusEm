function testVolumeTask(params)
    % ===========================================
    % testVolumeTask.m
    % Sub-task: otestování hlasitosti 
    %  - Zobrazí instrukce
    %  - Přehrává testovací zvuk
    %  - Umožní uživateli zkusit si změnit hlasitost (např. administrátor točí HW ovladačem)
    %  - Případně potvrdí klávesou, že je OK
    % ===========================================

    % 1) Příprava testovacího souboru, např. '02 Piste 2.wav' 
    testWav = fullfile(params.stimDir, 'Volume test', '02 Piste 2.wav');
    if ~exist(testWav, 'file')
        warning('Testovací WAV nenalezen: %s', testWav);
        return;
    end

    % 2) Zobrazení instrukcí na screen
    infoText = [ ...
        'Nyní se prosím ujistěte, že je hlasitost nastavena na příjemnou úroveň.\n' ...
        'Pro přehrání podnětu stiskněte mezerník.\n' ...
        'Až budete s hlasitostí spokojeni, stiskněte klávesu ENTER pro pokračování.\n' ...
        'Pokud potřebujete hlasitost změnit, informujte administrátora.' ];
    
    DrawFormattedText(params.win, infoText, 'center', 'center', [255 255 255]);
    Screen('Flip', params.win);

    spacePressed = false;

    while ~spacePressed
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('space'))
                spacePressed = true;
            end
        end
    end

    % 3) Po stisku mezerníku přehrajeme zvuk (lze i opakovaně)
    [y, freq] = audioread(testWav);
    % Pokud vaše audio zařízení vyžaduje určitou sampling freq, nastavte to při Open
    PsychPortAudio('FillBuffer', params.pahandle, y');
    PsychPortAudio('Start', params.pahandle, 1, 0, 1); % 1 = 1x přehrát, 0 = start hned
    WaitSecs(length(y)/freq); % počkáme, až se dohraje

    % 4) Čekáme na ENTER, abychom skončili test
    DrawFormattedText(params.win, 'Je hlasitost OK? Stiskni ENTER pro pokračování.', 'center', 'center', [255 255 0]);
    Screen('Flip', params.win);

    enterPressed = false;
    while ~enterPressed
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if sum(keyCode(KbName('Return')))
                enterPressed = true;
            end
        end
    end

    % 5) Vrátíme se zpět do runExperiment. Případně můžeme ukládat do results.
    %    Tady žádné velké logování nepotřebujeme. Pokud chcete, můžete:
    % results.volumeTestTimestamp = datestr(now);
    % save(...);

    % 6) Můžeme znovu vymazat buffer, pokud chceme.
%     PsychPortAudio('Stop', params.pahandle);
%     PsychPortAudio('FillBuffer', params.pahandle, []);
end
