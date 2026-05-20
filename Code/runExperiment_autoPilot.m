function runExperiment_autoPilot(subjID)
% runExperiment_autoPilot  End-to-end automated smoke test wrapper.
%
% Usage from MATLAB after cd Task/Code:
%   runExperiment_autoPilot('999')
%
% The real paradigm is still used: stimuli are loaded, audio playback and room
% microphone recording are executed, triggers are sent, schedules are saved, and
% result rows are appended. Only participant clicks/joystick choices are synthetic.

    if nargin < 1 || isempty(subjID)
        subjID = sprintf('AUTO_%s', datestr(now,'yyyymmdd_HHMMSS'));
    end

    setenv('MUSEM_AUTOPILOT','1');
    setenv('MUSEM_SUBJID', char(subjID));
    setenv('MUSEM_AUTOPILOT_RESUME_ACTION','R');

    fprintf('MusEm autoPilot smoke test enabled. Synthetic subject ID: %s\n', char(subjID));
    runExperiment();
end
