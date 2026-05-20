function checkAbort()
% checkAbort  Abort the experiment if ESC is pressed.
% The top-level try/catch in runExperiment saves params before closing.
    [keyIsDown,~,keyCode] = KbCheck;
    if keyIsDown
        esc = KbName('ESCAPE');
        if any(keyCode(esc))
            error('Experiment aborted by user (ESC).');
        end
    end
end
