%% LUFS-normalizace všech WAV souborů v adresáři
% Vyplňte cestu k adresářům a cílovou loudness (v LUFS)
inputDir   = './Practice - wav';
outputDir  = './Practice - wav_norm';
targetLUFS = -16;  % cílová integrovaná loudness, např. -16 LUFS

% Vytvoří výstupní adresář, pokud neexistuje
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

% Načte seznam všech WAV souborů
wavFiles = dir(fullfile(inputDir,'*.wav'));

% Pro každý soubor:
for k = 1:numel(wavFiles)
    % vstupní cesta a jméno
    inFile = fullfile(inputDir, wavFiles(k).name);
    % načtení audio signálu
    [y, fs] = audioread(inFile);
    
    % 1) změření integrované loudness (vyžaduje Audio Toolbox)
    I = integratedLoudness(y, fs);
    
    % 2) výpočet gainu v dB a lineární škály
    gainDB = targetLUFS - I;
    gainLin = 10^(gainDB/20);
    
    % 3) aplikace gainu
    yNorm = y * gainLin;
    
    % 4) jednoduché ošetření clippingu (true-peak limiting)
    pk = max(abs(yNorm), [], 'all');
    if pk > 1
        yNorm = yNorm / pk * 0.999;  % přeskálování, aby max < 1
    end
    
    % 5) uložení normalizovaného souboru
    outFile = fullfile(outputDir, wavFiles(k).name);
    audiowrite(outFile, yNorm, fs);
    
    fprintf('[%d/%d] %s → %s  (I=%.1f LUFS, gain=%+.1f dB)\n', ...
        k, numel(wavFiles), wavFiles(k).name, wavFiles(k).name, I, gainDB);
end
