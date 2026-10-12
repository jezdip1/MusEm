# MusEm: nasazení na KISARGRYZEN26

Připravený laboratorní kandidát, nikoli potvrzení funkčního měření na novém PC.
Výchozí kód odpovídá nahranému snapshotu. Kontrola byla provedena přes Git blob SHA.

## Instalace

Z kořene tohoto balíčku nebo čistého checkoutu kandidátní větve:

```bash
sudo python3 scripts/install_lab.py --stimuli '/cesta/k/puvodni/slozce/Stimuli'
```

Bez parametru `--stimuli` se připraví kód a launchery. Hlavní spuštění zůstane
blokované, dokud není importována úplná a ověřená sada stimulů. Stejný příkaz
lze později zopakovat s `--stimuli`. Zdrojové soubory se kopírují, nepřesouvají.
Vyžaduje existující účet `laboperator`, skupinu `hammerlab`, Python 3 a MATLAB R2024b.
Instalátor nevytváří účty, neinstaluje MATLAB a nemění ostatní paradigmata.

- Kód: `/srv/hammerlab/paradigms/MusEm/releases/v0.1.0-rc1-kisargryzen26`
- Aktivní verze: `/srv/hammerlab/paradigms/MusEm/current`
- Stimuly: `/data/stimuli/MusEm/snapshot-20261012`
- Výsledky: `/data/results/MusEm`
- Konfigurace: `/srv/hammerlab/config/MusEm.env`

Instalátor zachovává existující konfiguraci a stejnojmenný release nepřepíše
odlišným obsahem. Každé spuštění ověří kód; main/preflight ověřuje i obsah celé
sady stimulů. Plná sada se bere ze snapshotu, nikoli automaticky ze staršího Gitu.
Pokud existující konfigurace ukazuje jinam, zkontrolujte její cesty před testem.

## Provozní změny

- MATLAB s GUI, jednoznačná cesta k hlavní funkci a launchery pro kontrolu,
  zařízení, FF, 00, výsledky a návod.
- Konfigurace obrazovky, zvuku, mikrofonu, Pico portu, stimulů a výsledků mimo kód.
- Žádné pevné sériové číslo Pico ani cesta do účtu bciadmin.
- Evidence verze v `params.Runtime`, kontrola souborů před spuštěním.
- Obnova aktuálních hardwarových objektů a cest při pokračování; starý výsledek
  se při Restart nejprve přejmenuje na zálohu.
- MusEm: zapnuté PTB sync testy, cleanup i při chybě inicializace, uložení bez
  aktivních hardwarových objektů. MixEm: zachována původní stavová logika triggerů.

## Stimuly

Doplnit celou Task/Stimuli. Nestačí WAV: nutný je také Imp/imp_rating_task_map.csv, Imp/Practice - wav, Imp/Subset Imp - wav, Affect_Em/Practice - wav, oba Affect_Em/Subset N - 40 - wav a Volume test/02 Piste 2.wav.

Instrukce pro obsluhu jsou v `OPERATING.txt`. Jádro experimentu bylo zachováno;
plný běh, synchronizace PTB, příjem TTL a zvuk/nahrávání musí být ověřeny lokálně.
V tomto prostředí není MATLAB, Psychtoolbox ani zařízení laboratoře.

## Vyřazené pomocné koncepty

Do instalace se nekopírují dva nepoužívané koncepty ze snapshotu:
`Code/makeTriggerCodesTable.m` (skript obsahující další classdef, syntaktická chyba)
a `Code/doEmTrial2.m` (duplicitní návrh se jménem funkce doEmTrial).
Aktivní `Code/TriggerCodes.m` a `Code/doEmTrial.m` jsou byte-for-byte původní.
Soubory zůstávají zachovány v originálním snapshotu a původní Git historii.
