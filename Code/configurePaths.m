function params = configurePaths(params, baseDir)
% configurePaths  Rebuild machine-specific runtime paths from the project root.
% Safe to call both at fresh start and after loading a resumed params struct.

    lab = hammer.config('MusEm', baseDir);
    params.Runtime = lab.Runtime;
    params.baseDir       = baseDir;
    params.pngDir        = fullfile(baseDir,'PNG');
    params.stimDirImp    = fullfile(lab.stimuli,'Imp');
    params.stimDirAffect = fullfile(lab.stimuli,'Affect_Em');
    params.stimDirEm     = fullfile(lab.stimuli,'Affect_Em');
    params.stimVolTest   = fullfile(lab.stimuli,'Volume test');
    params.resultsDir    = lab.results;
    if ~exist(params.resultsDir,'dir'), mkdir(params.resultsDir); end

    params.recordingsDir = fullfile(params.resultsDir,'Recordings', char(params.subjID));
    if ~exist(params.recordingsDir,'dir'), mkdir(params.recordingsDir); end

    params.dataFile = fullfile(params.resultsDir, sprintf('%s.mat', char(params.subjID)));

    if isfield(params,'masterSchedule')
        params.masterSchedule = hammer.rebaseSchedule(params.masterSchedule, lab.stimuli);
    end
end
