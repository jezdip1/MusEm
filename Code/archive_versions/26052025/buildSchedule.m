function tbl = buildSchedule(cond, stimDir, nPractice, nPerBlock, nBlocks, subsetNum)
% buildSchedule  –  Vytvoří tabulku practice + experimental trialů
%   cond       : 'Imp', 'Affect' nebo 'Em'
%   stimDir    : cesta k hlavní složce pro danou podmínku
%   nPractice  : počet practice trialů
%   nPerBlock  : počet trialů na blok
%   nBlocks    : počet bloků v experimentu
%   subsetNum  : pro Affect/Em číslo subsetu (1 nebo 2)
%
% Výstup:
%   tbl – MATLAB table s proměnnými:
%     Condition, IsPractice, WavPath, TaskType, TrialIndex, Block

    %% --- definice sloupců a prázdné tabulky ---
    cols = {'Condition','IsPractice','WavPath','TaskType','TrialIndex','Block'};
    tbl  = table( ...
      'Size',          [0,numel(cols)], ...
      'VariableTypes', {'string','logical','string','string','double','double'}, ...
      'VariableNames', cols);

    %% --- Practice trials --------------------------------------------
    pracDir   = fullfile(stimDir,'Practice - wav');
    pracFiles = dir(fullfile(pracDir,'*.wav'));
    P = {pracFiles.name}';
    P = P(randperm(numel(P), nPractice));

    % úkoly pro practice podle kondice
    switch cond
      case 'Imp'
        ptasks = [ repmat("num", nPractice/2, 1); repmat("type", nPractice/2, 1) ];
        ptasks = ptasks(randperm(nPractice));
      case 'Affect'
        ptasks = repmat("dim", nPractice, 1);
      case 'Em'
        ptasks = repmat("disc", nPractice, 1);
      otherwise
        error('Unknown condition %s', cond);
    end

    Tprac = table( ...
      repmat({cond}, nPractice, 1), ...          % Condition
      true(nPractice,1), ...                      % IsPractice
      fullfile(pracDir, P), ...                   % WavPath
      cellstr(ptasks), ...                        % TaskType
      (1:nPractice)', ...                         % TrialIndex
      zeros(nPractice,1), ...                     % Block
      'VariableNames', cols);

    %% --- Experimental trials ----------------------------------------
    if strcmp(cond,'Imp')
        subDir = fullfile(stimDir,'Subset Imp - wav');
    else
        % pro Affect/Em použijeme subsetNum
        subDir = fullfile(stimDir, sprintf('Subset %d - 40 - wav', subsetNum));
    end

    expFiles = dir(fullfile(subDir,'*.wav'));
    E        = {expFiles.name}';
    E        = E(randperm(numel(E), nPerBlock * nBlocks));

    switch cond
      case 'Imp'
        etasks = [ repmat("num", nPerBlock, 1); repmat("type", nPerBlock, 1) ];
        etasks = etasks(randperm(numel(etasks)));
      case 'Affect'
        etasks = repmat("dim", nPerBlock*nBlocks, 1);
      case 'Em'
        etasks = repmat("disc", nPerBlock*nBlocks, 1);
      otherwise
        error('Unknown condition %s', cond);
    end

    blk = repelem((1:nBlocks)', nPerBlock);
    idx = repmat((1:nPerBlock)', nBlocks, 1);

    Texp = table( ...
      repmat({cond}, numel(E), 1), ...             % Condition
      false(numel(E),1), ...                       % IsPractice
      fullfile(subDir, E), ...                     % WavPath
      cellstr(etasks), ...                          % TaskType
      idx, blk, ...                                 % TrialIndex, Block
      'VariableNames', cols);

    %% --- spojení practice + experimental ---------------------------
    tbl = [Tprac; Texp];
end
