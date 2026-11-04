$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$Cli = @{ Template = ''; Apply = $false; Yes = $false; List = $false; Help = $false; Lang = ''; Bad = $null }
for ($ai = 0; $ai -lt $args.Count; $ai++) {
    $v = [string]$args[$ai]
    if ($v -match '^(--?template|-t)$') {
        $ai++
        if ($ai -lt $args.Count) { $Cli.Template = [string]$args[$ai] } else { $Cli.Bad = @('--template needs a path to a .toml file', '') }
    }
    elseif ($v -match '^--?template[=:](.+)$') { $Cli.Template = $Matches[1] }
    elseif ($v -match '^--?lang(uage)?$') {
        $ai++
        if ($ai -lt $args.Count) { $Cli.Lang = ([string]$args[$ai]).ToLower() } else { $Cli.Bad = @('--lang needs en or pl', '') }
    }
    elseif ($v -match '^--?lang(uage)?[=:](\w+)$') { $Cli.Lang = $Matches[2].ToLower() }
    elseif ($v -match '^--?apply$') { $Cli.Apply = $true }
    elseif ($v -match '^(--?yes|-y)$') { $Cli.Yes = $true }
    elseif ($v -match '^(--?list|-l)$') { $Cli.List = $true }
    elseif ($v -match '^(--?help|-h|-\?|/\?)$') { $Cli.Help = $true }
    elseif ($v -match '\.toml$' -and -not $Cli.Template) { $Cli.Template = $v }
    else { $Cli.Bad = @('Unknown option: {0}', $v) }
}
if ($Cli.Apply -and -not $Cli.Template) { $Cli.Bad = @('--apply needs --template <file.toml>', '') }
if ($Cli.Lang -and $Cli.Lang -notin 'en', 'pl') { $Cli.Bad = @('Unknown language: {0} (use en or pl)', $Cli.Lang) }

function U { param([string]$s) [regex]::Unescape($s) }
$PL = [System.Collections.Hashtable]::new([StringComparer]::Ordinal)
@(
    ,@('(real results depend on the game, settings and drivers)', (U '(rzeczywiste wyniki zale\u017c\u0105 od gry, ustawie\u0144 i sterownik\u00f3w)'))
    ,@('({0:+0;-0;0}% to {1:+0;-0;0}%)', '({0:+0;-0;0}% do {1:+0;-0;0}%)')
    ,@('({0:+0;-0;0}% to {1:+0;-0;0}%) from a base of {2} FPS', '({0:+0;-0;0}% do {1:+0;-0;0}%) przy bazie {2} FPS')
    ,@('--apply                  Apply the template right away without opening the menu', '--apply                  Zastosuj szablon od razu, bez otwierania menu')
    ,@('--help                   Show this help', (U '--help                   Poka\u017c t\u0119 pomoc'))
    ,@('--lang <en|pl>           Interface language (default: saved choice or Windows language)', (U '--lang <en|pl>           J\u0119zyk interfejsu (domy\u015blnie: zapisany wyb\u00f3r lub j\u0119zyk Windows)'))
    ,@('--list                   Print every tweak ID, category and restart requirement', '--list                   Wypisz wszystkie ID poprawek, kategorie i wymagania restartu')
    ,@('--template <file.toml>   Load a TOML template and preselect its tweaks, DNS and settings', '--template <plik.toml>   Wczytaj szablon TOML i zaznacz jego poprawki, DNS i ustawienia')
    ,@('--yes                    Skip confirmation and pauses (use with --apply for unattended runs)', (U '--yes                    Pomi\u0144 potwierdzenia i pauzy (z --apply do pracy bez nadzoru)'))
    ,@('CodeOpt - Windows Tweaks & Optimizer', 'CodeOpt - Optymalizator Windows')
    ,@('Usage: .\CodeOpt.ps1 [options]', (U 'U\u017cycie: .\\CodeOpt.ps1 [opcje]'))
    ,@('Examples:', (U 'Przyk\u0142ady:'))
    ,@('--template needs a path to a .toml file', (U '--template wymaga \u015bcie\u017cki do pliku .toml'))
    ,@('Unknown option: {0}', 'Nieznana opcja: {0}')
    ,@('--apply needs --template <file.toml>', '--apply wymaga --template <plik.toml>')
    ,@('Unknown language: {0} (use en or pl)', (U 'Nieznany j\u0119zyk: {0} (u\u017cyj en lub pl)'))
    ,@('--lang needs en or pl', '--lang wymaga en lub pl')
    ,@('APPLY', (U 'DZIA\u0141ANIE'))
    ,@('CATEGORY', 'KATEGORIA')
    ,@('RECOMMENDED', 'ZALECANE')
    ,@('yes', 'tak')
    ,@('instant', 'od razu')
    ,@('restart', 'restart')
    ,@('sign out', 'wylogowanie')
    ,@('All changes are active now. No restart needed.', (U 'Wszystkie zmiany ju\u017c dzia\u0142aj\u0105. Restart nie jest potrzebny.'))
    ,@('Apply', 'Aktywacja')
    ,@('BASE', 'BAZA')
    ,@('BOTTLENECK', (U 'W\u0104SKIE GARD\u0141O'))
    ,@('CUSTOM DNS', (U 'W\u0141ASNY DNS'))
    ,@('Category {0}/{1}', 'Kategoria {0}/{1}')
    ,@('CodeOpt closed. Restart to apply all changes.', (U 'CodeOpt zamkni\u0119ty. Uruchom ponownie komputer, aby zastosowa\u0107 wszystkie zmiany.'))
    ,@('CodeOpt needs administrator rights. Requesting elevation...', (U 'CodeOpt wymaga uprawnie\u0144 administratora. Prosz\u0119 o ich nadanie...'))
    ,@('Could not relaunch automatically. Open PowerShell as Administrator and run CodeOpt again.', (U 'Nie uda\u0142o si\u0119 uruchomi\u0107 ponownie automatycznie. Otw\u00f3rz PowerShell jako administrator i uruchom CodeOpt jeszcze raz.'))
    ,@('DEVICE', (U 'URZ\u0104DZENIE'))
    ,@('DISK', 'DYSK')
    ,@('DISPLAY', 'EKRAN')
    ,@('DNS providers:', 'Dostawcy DNS:')
    ,@('Desktop', 'Stacjonarny')
    ,@('Laptop', 'Laptop')
    ,@('Elevation was cancelled. CodeOpt cannot apply tweaks without administrator rights.', (U 'Anulowano nadanie uprawnie\u0144. CodeOpt nie mo\u017ce zastosowa\u0107 poprawek bez uprawnie\u0144 administratora.'))
    ,@('Enter/Space', 'Enter/Spacja')
    ,@('Space', 'Spacja')
    ,@('Est.', 'Szac.')
    ,@('Est. total gain', (U 'Szac. \u0142\u0105czny zysk'))
    ,@('Estimated gain', 'Szacowany zysk')
    ,@('Estimated gain:', 'Szacowany zysk:')
    ,@('FASTEST', 'NAJSZYBSZY')
    ,@('File not found: {0}', 'Nie znaleziono pliku: {0}')
    ,@('IPv4 or IPv6, leave secondary empty to use one server', (U 'IPv4 lub IPv6, zostaw zapasowy pusty, aby u\u017cy\u0107 jednego serwera'))
    ,@('Invalid DNS address: {0}', (U 'Nieprawid\u0142owy adres DNS: {0}'))
    ,@('Invalid address. Press any key...', (U 'Nieprawid\u0142owy adres. Naci\u015bnij dowolny klawisz...'))
    ,@('Invalid value: {0}', (U 'Nieprawid\u0142owa warto\u015b\u0107: {0}'))
    ,@('Line {0}: cannot read ''{1}''', (U 'Wiersz {0}: nie mo\u017cna odczyta\u0107 ''{1}'''))
    ,@('Load it with', 'Wczytaj go poleceniem')
    ,@('Measuring ping to DNS providers...', (U 'Mierz\u0119 ping do dostawc\u00f3w DNS...'))
    ,@('NOTES', 'UWAGI')
    ,@('Needs', 'Wymaga')
    ,@('No restart needed', 'Bez restartu')
    ,@('Off', (U 'Wy\u0142.'))
    ,@('On', (U 'W\u0142.'))
    ,@('PRIMARY', (U 'G\u0141\u00d3WNY'))
    ,@('PROVIDER', 'DOSTAWCA')
    ,@('SECONDARY', 'ZAPASOWY')
    ,@('Press any key to continue, Esc to quit...', (U 'Naci\u015bnij dowolny klawisz, aby kontynuowa\u0107, lub Esc, aby wyj\u015b\u0107...'))
    ,@('Press any key to exit...', (U 'Naci\u015bnij dowolny klawisz, aby wyj\u015b\u0107...'))
    ,@('Press any key to return to the menu...', (U 'Naci\u015bnij dowolny klawisz, aby wr\u00f3ci\u0107 do menu...'))
    ,@('Press any key...', (U 'Naci\u015bnij dowolny klawisz...'))
    ,@('Primary   :', (U 'G\u0142\u00f3wny    :'))
    ,@('Secondary :', 'Zapasowy  :')
    ,@('Ready to apply', 'Gotowe do zastosowania:')
    ,@('tweaks.', 'poprawek.')
    ,@('Restart required', 'Wymagany restart')
    ,@('Restarting in 5 seconds...', 'Restart za 5 sekund...')
    ,@('Restart now?', (U 'Uruchomi\u0107 ponownie teraz?'))
    ,@('Sign out now?', (U 'Wylogowa\u0107 teraz?'))
    ,@('SELECT DNS PROVIDER', (U 'WYBIERZ DOSTAWC\u0118 DNS'))
    ,@('Selected', 'Zaznaczono')
    ,@('of {0}', 'z {0}')
    ,@('Selection needs', 'Zaznaczenie wymaga')
    ,@('Sign out required', 'Wymagane wylogowanie')
    ,@('Signing out...', 'Wylogowywanie...')
    ,@('TEMPLATE', 'SZABLON')
    ,@('TEMPLATE WARNINGS', (U 'OSTRZE\u017bENIA SZABLONU'))
    ,@('Template saved', 'Zapisano szablon')
    ,@('The template could not be loaded. Press any key to open the menu...', (U 'Nie uda\u0142o si\u0119 wczyta\u0107 szablonu. Naci\u015bnij dowolny klawisz, aby otworzy\u0107 menu...'))
    ,@('The template selects no tweaks. Nothing to apply.', (U 'Szablon nie zaznacza \u017cadnych poprawek. Nie ma czego zastosowa\u0107.'))
    ,@('Type the FPS you get now in your game for exact numbers. Leave empty for the hardware estimate.', (U 'Wpisz, ile FPS masz teraz w grze, aby dosta\u0107 dok\u0142adne liczby. Zostaw puste, aby u\u017cy\u0107 szacunku sprz\u0119towego.'))
    ,@('Unknown DNS provider ''{0}''', 'Nieznany dostawca DNS ''{0}''')
    ,@('Unknown category ''{0}''', 'Nieznana kategoria ''{0}''')
    ,@('Unknown key {0}', 'Nieznany klucz {0}')
    ,@('Unknown preset ''{0}'' (use none, recommended, fps, privacy or all)', (U 'Nieznany preset ''{0}'' (u\u017cyj none, recommended, fps, privacy lub all)'))
    ,@('Unknown section [{0}]', 'Nieznana sekcja [{0}]')
    ,@('Unknown tweak ID ''{0}''', 'Nieznane ID poprawki ''{0}''')
    ,@('Unknown tweak ID ''{0}'' in {1}', 'Nieznane ID poprawki ''{0}'' w {1}')
    ,@('Using {0}{1}. {2}. Press Space to change.', (U 'U\u017cywany: {0}{1}. {2}. Naci\u015bnij Spacj\u0119, aby zmieni\u0107.'))
    ,@('Windows Tweaks & Optimizer', 'Optymalizator Windows')
    ,@('Your FPS:', 'Twoje FPS:')
    ,@('[Y] yes  [N] later', (U '[T] tak  [N] p\u00f3\u017aniej'))
    ,@('all in tab', (U 'ca\u0142a karta'))
    ,@('apply', 'zastosuj')
    ,@('back', (U 'wr\u00f3\u0107'))
    ,@('by {0}', 'autor: {0}')
    ,@('cancel', 'anuluj')
    ,@('category', 'kategoria')
    ,@('clear', (U 'wyczy\u015b\u0107'))
    ,@('confirm', (U 'potwierd\u017a'))
    ,@('dns.provider = ''custom'' needs dns.primary', 'dns.provider = ''custom'' wymaga dns.primary')
    ,@('done', 'gotowe')
    ,@('exit', (U 'wyj\u015bcie'))
    ,@('export template', 'eksport szablonu')
    ,@('language PL/EN', (U 'j\u0119zyk PL/EN'))
    ,@('more', (U 'wi\u0119cej'))
    ,@('move', 'ruch')
    ,@('my FPS', 'moje FPS')
    ,@('no FPS change', 'bez zmiany FPS')
    ,@('no direct FPS impact', (U 'brak bezpo\u015bredniego wp\u0142ywu na FPS'))
    ,@('none', 'brak')
    ,@('not available', (U 'niedost\u0119pne'))
    ,@('pick fastest', 'wybierz najszybszy')
    ,@('ping is measured from this PC', 'ping mierzony z tego komputera')
    ,@('recommended', 'zalecane')
    ,@('select', 'wybierz')
    ,@('settings.base_fps must be a whole number above 0', (U 'settings.base_fps musi by\u0107 liczb\u0105 ca\u0142kowit\u0105 wi\u0119ksz\u0105 od 0'))
    ,@('settings.language must be en or pl', (U 'settings.language musi mie\u0107 warto\u015b\u0107 en lub pl'))
    ,@('settings.restart must be ask, never or always', (U 'settings.restart musi mie\u0107 warto\u015b\u0107 ask, never lub always'))
    ,@('test ping again', 'zmierz ping ponownie')
    ,@('timeout', 'brak odp.')
    ,@('toggle / pick', 'zaznacz / wybierz')
    ,@('unselect', 'odznacz')
    ,@('x failed', (U 'x b\u0142\u0105d'))
    ,@('{0} FPS (yours)', '{0} FPS (Twoje)')
    ,@('{0} instant', 'od razu: {0}')
    ,@('{0} must be true or false', (U '{0} musi mie\u0107 warto\u015b\u0107 true lub false'))
    ,@('{0} restart', 'restart: {0}')
    ,@('{0} restart, {1} sign out', 'restart: {0}, wylogowanie: {1}')
    ,@('{0} sign out', 'wylogowanie: {0}')
    ,@('REC', 'ZAL')
    ,@('{0} tweak(s) need a restart to take effect.', (U 'Poprawki wymagaj\u0105ce restartu: {0}.'))
    ,@('{0} tweak(s) need you to sign out and back in.', (U 'Poprawki wymagaj\u0105ce ponownego zalogowania: {0}.'))
    ,@('{0} warning(s)', (U 'ostrze\u017cenia: {0}'))
    ,@('~{0} FPS est.', '~{0} FPS szac.')
    ,@('Safety', 'Ochrona')
    ,@('Power', 'Zasilanie')
    ,@('Gaming', 'Gry')
    ,@('Input', 'Sterowanie')
    ,@('Network', (U 'Sie\u0107'))
    ,@('Privacy', (U 'Prywatno\u015b\u0107'))
    ,@('Cleanup', 'Czyszczenie')
    ,@('Debloat', 'Odchudzanie')
    ,@('Automatic (DHCP)', 'Automatyczny (DHCP)')
    ,@('Custom...', (U 'W\u0142asny...'))
    ,@('Custom', (U 'W\u0142asny'))
    ,@('Fast anycast, privacy-first', (U 'Szybki anycast, nacisk na prywatno\u015b\u0107'))
    ,@('Blocks malware', (U 'Blokuje z\u0142o\u015bliwe oprogramowanie'))
    ,@('Blocks malware and adult content', (U 'Blokuje malware i tre\u015bci dla doros\u0142ych'))
    ,@('Very reliable, huge network', (U 'Bardzo niezawodny, ogromna sie\u0107'))
    ,@('Blocks malware, Swiss privacy', (U 'Blokuje malware, szwajcarska prywatno\u015b\u0107'))
    ,@('Cisco, phishing protection', 'Cisco, ochrona przed phishingiem')
    ,@('Blocks adult content', (U 'Blokuje tre\u015bci dla doros\u0142ych'))
    ,@('Blocks ads and trackers', 'Blokuje reklamy i trackery')
    ,@('Ads, trackers and adult content', (U 'Reklamy, trackery i tre\u015bci dla doros\u0142ych'))
    ,@('No filtering', 'Bez filtrowania')
    ,@('No filtering, low latency', (U 'Bez filtrowania, niskie op\u00f3\u017anienie'))
    ,@('Blocks malware and phishing', 'Blokuje malware i phishing')
    ,@('Strict family filter', (U '\u015acis\u0142y filtr rodzinny'))
    ,@('Blocks malicious sites', (U 'Blokuje z\u0142o\u015bliwe strony'))
    ,@('Reset to your router or ISP DNS', 'Przywraca DNS routera lub dostawcy internetu')
    ,@('Enter your own server addresses', (U 'Wpisz w\u0142asne adresy serwer\u00f3w'))
    ,@('Your own servers', (U 'Twoje w\u0142asne serwery'))
    ,@('laptop power limits relaxed', (U 'lu\u017aniejsze limity mocy laptopa'))
    ,@('CPU clocks held higher', (U 'wy\u017csze taktowanie CPU'))
    ,@('clocks stay boosted', 'taktowanie pozostaje podbite')
    ,@('only {0} threads, parking hurts more', (U 'tylko {0} w\u0105tk\u00f3w, parkowanie szkodzi bardziej'))
    ,@('fewer core wake-ups', (U 'mniej wybudze\u0144 rdzeni'))
    ,@('integrated GPU, no PCIe link to tune', (U 'zintegrowane GPU, brak \u0142\u0105cza PCIe do strojenia'))
    ,@('laptop link power saving is aggressive', (U 'laptop agresywnie oszcz\u0119dza energi\u0119 \u0142\u0105cza'))
    ,@('GPU link stays at full speed', (U '\u0142\u0105cze GPU dzia\u0142a z pe\u0142n\u0105 pr\u0119dko\u015bci\u0105'))
    ,@('laptops throttle background threads hard', (U 'laptopy mocno d\u0142awi\u0105 w\u0105tki w tle'))
    ,@('small effect on desktops', (U 'ma\u0142y efekt na komputerach stacjonarnych'))
    ,@('limited CPU/RAM gains from prioritizing', (U 's\u0142abszy CPU/RAM zyskuje na priorytecie'))
    ,@('mostly helps 1% lows', (U 'g\u0142\u00f3wnie poprawia 1% low'))
    ,@('Game DVR is already off', (U 'Game DVR jest ju\u017c wy\u0142\u0105czony'))
    ,@('background capture costs a weaker GPU more', (U 'nagrywanie w tle bardziej obci\u0105\u017ca s\u0142absze GPU'))
    ,@('stops background capture', 'zatrzymuje nagrywanie w tle')
    ,@('exclusive fullscreen games only', (U 'tylko gry w trybie wy\u0142\u0105cznego pe\u0142nego ekranu'))
    ,@('borderless and windowed games', 'gry w oknie i bez ramki')
    ,@('GPU does not support HAGS', (U 'GPU nie obs\u0142uguje HAGS'))
    ,@('CPU-bound, offloads scheduling to GPU', 'limit CPU, planowanie przeniesione na GPU')
    ,@('GPU-bound, small gain', (U 'limit GPU, ma\u0142y zysk'))
    ,@('mainly smoother frametimes', (U 'g\u0142\u00f3wnie p\u0142ynniejsze czasy klatek'))
    ,@('CPU-bound, game gets longer time slices', (U 'limit CPU, gra dostaje d\u0142u\u017csze kwanty czasu'))
    ,@('improves 1% lows more than average FPS', (U 'poprawia bardziej 1% low ni\u017c \u015brednie FPS'))
    ,@('only helps if HPET was forced on', (U 'pomaga tylko, gdy HPET by\u0142 wymuszony'))
    ,@('fixes stutter, little FPS change', (U 'naprawia zaci\u0119cia, ma\u0142a zmiana FPS'))
    ,@('VBS is already off on this PC', (U 'VBS jest ju\u017c wy\u0142\u0105czony na tym PC'))
    ,@('VBS is on and you are CPU-bound', (U 'VBS jest w\u0142\u0105czony i masz limit CPU'))
    ,@('VBS is on', (U 'VBS jest w\u0142\u0105czony'))
    ,@('less background CPU', (U 'mniejsze u\u017cycie CPU w tle'))
    ,@('no NVIDIA GPU detected', 'nie wykryto GPU NVIDIA')
    ,@('frees a weaker CPU', (U 'odci\u0105\u017ca s\u0142abszy CPU'))
    ,@('prevents random background spikes', 'zapobiega losowym skokom w tle')
    ,@('frees RAM', 'zwalnia RAM')
    ,@('iGPU shares load with desktop effects', 'iGPU dzieli moc z efektami pulpitu')
    ,@('lighter desktop compositor work', (U 'l\u017cejsza praca kompozytora pulpitu'))
    ,@('iGPU skips blur work', 'iGPU nie liczy rozmycia')
    ,@('small on a dedicated GPU', (U 'ma\u0142y efekt na dedykowanym GPU'))
    ,@('only {0} GB RAM', 'tylko {0} GB RAM')
    ,@('fewer background processes', (U 'mniej proces\u00f3w w tle'))
    ,@('low RAM: compression helps, keep it on', (U 'ma\u0142o RAM: kompresja pomaga, zostaw j\u0105'))
    ,@('enough RAM, less CPU overhead', (U 'wystarczaj\u0105co RAM, mniejsze obci\u0105\u017cenie CPU'))
    ,@('borderline RAM amount', (U 'graniczna ilo\u015b\u0107 RAM'))
    ,@('HDD loads benefit from SysMain', 'wczytywanie z HDD korzysta z SysMain')
    ,@('less background disk work', 'mniej pracy dysku w tle')
    ,@('indexing keeps the HDD busy', (U 'indeksowanie obci\u0105\u017ca HDD'))
    ,@('less background I/O', 'mniej operacji dyskowych w tle')
    ,@('fewer background apps', 'mniej aplikacji w tle')
) | ForEach-Object { $PL[$_[0]] = $_[1] }

$TweakPl = @{
    'create_system_restore_point' = @((U 'Utw\u00f3rz punkt przywracania'), (U 'Tworzy punkt przywracania, aby ka\u017cd\u0105 zmian\u0119 mo\u017cna by\u0142o cofn\u0105\u0107 w Przywracaniu systemu.'))
    'backup_registry_hives' = @('Kopia zapasowa rejestru', 'Eksportuje HKLM\SYSTEM i HKCU\Software do Dokumenty\CodeOpt-Backup.')
    'ultimate_performance_plan' = @((U 'Plan Najwy\u017csza wydajno\u015b\u0107'), (U 'Odblokowuje i w\u0142\u0105cza dostrojony plan zasilania Ultimate Performance.'))
    'disable_core_parking' = @((U 'Wy\u0142\u0105cz parkowanie rdzeni'), (U 'Wszystkie rdzenie CPU pozostaj\u0105 aktywne, bez op\u00f3\u017anie\u0144 przy wybudzaniu.'))
    'disable_usb_selective_suspend' = @((U 'Wy\u0142\u0105cz usypianie USB'), (U 'Urz\u0105dzenia USB, np. mysz i s\u0142uchawki, nie przechodz\u0105 w u\u015bpienie.'))
    'disable_pcie_link_state_power_saving' = @((U 'Wy\u0142\u0105cz oszcz\u0119dzanie energii PCIe'), (U 'Wy\u0142\u0105cza ASPM, aby \u0142\u0105cza GPU i NVMe dzia\u0142a\u0142y z pe\u0142n\u0105 pr\u0119dko\u015bci\u0105.'))
    'disable_power_throttling' = @((U 'Wy\u0142\u0105cz d\u0142awienie energii'), (U 'Windows przestaje ogranicza\u0107 procesy dzia\u0142aj\u0105ce w tle.'))
    'disable_hibernation' = @((U 'Wy\u0142\u0105cz hibernacj\u0119'), (U 'Wy\u0142\u0105cza hibernacj\u0119 i usuwa hiberfil.sys, zwalniaj\u0105c miejsce na dysku.'))
    'disable_fast_startup' = @((U 'Wy\u0142\u0105cz szybkie uruchamianie'), (U 'Wymusza czysty start za ka\u017cdym razem, naprawia problemy ze sterownikami.'))
    'enable_game_mode' = @((U 'W\u0142\u0105cz tryb gry'), 'Windows nadaje priorytet grze i wstrzymuje aktualizacje w tle.')
    'disable_game_bar_game_dvr' = @((U 'Wy\u0142\u0105cz Game Bar i Game DVR'), (U 'Usuwa nagrywanie w tle i nak\u0142adk\u0119 Xbox Game Bar.'))
    'disable_fullscreen_optimizations' = @((U 'Wy\u0142\u0105cz optymalizacje pe\u0142nego ekranu'), (U 'U\u017cywa wy\u0142\u0105cznego pe\u0142nego ekranu dla mniejszego input laga.'))
    'optimizations_for_windowed_games' = @('Optymalizacje gier w oknie', (U 'W\u0142\u0105cza model prezentacji flip dla gier w oknie i bez ramki.'))
    'hardware_accelerated_gpu_scheduling' = @((U 'Sprz\u0119towe planowanie GPU (HAGS)'), (U 'GPU samo zarz\u0105dza planowaniem pami\u0119ci. Wymaga obs\u0142ugiwanej karty.'))
    'mmcss_game_priority' = @('Priorytet gier MMCSS', 'Podnosi priorytet planowania GPU i CPU dla gier.')
    'cpu_priority_separation' = @((U 'Separacja priorytet\u00f3w CPU'), (U 'Kr\u00f3tkie, zmienne kwanty czasu faworyzuj\u0105ce aplikacj\u0119 na pierwszym planie (0x26).'))
    'global_timer_resolution' = @((U 'Globalna rozdzielczo\u015b\u0107 zegara'), (U '\u017b\u0105dania wysokiej rozdzielczo\u015bci zegara dzia\u0142aj\u0105 w ca\u0142ym systemie.'))
    'disable_dynamic_tick' = @((U 'Wy\u0142\u0105cz dynamiczny tick'), (U 'Zegar systemowy tyka ze sta\u0142\u0105 cz\u0119stotliwo\u015bci\u0105.'))
    'disable_hpet_platform_clock' = @((U 'Wy\u0142\u0105cz zegar platformy HPET'), (U 'Usuwa wymuszony HPET na rzecz szybszego \u017ar\u00f3d\u0142a czasu.'))
    'disable_multiplane_overlay_mpo' = @((U 'Wy\u0142\u0105cz Multiplane Overlay (MPO)'), (U 'Naprawia migotanie i zaci\u0119cia na niekt\u00f3rych kartach NVIDIA i przy wielu monitorach.'))
    'disable_vbs_memory_integrity' = @((U 'Wy\u0142\u0105cz VBS i integralno\u015b\u0107 pami\u0119ci'), (U 'Wi\u0119cej FPS na niekt\u00f3rych CPU, ale ni\u017csze bezpiecze\u0144stwo systemu.'))
    'disable_nvidia_telemetry' = @((U 'Wy\u0142\u0105cz telemetri\u0119 NVIDIA'), (U 'Wy\u0142\u0105cza zadania, us\u0142ug\u0119 i zgod\u0119 na telemetri\u0119 NVIDIA.'))
    'disable_mouse_acceleration' = @((U 'Wy\u0142\u0105cz akceleracj\u0119 myszy'), (U 'Wy\u0142\u0105cza "Zwi\u0119ksz precyzj\u0119 wska\u017anika" dla celowania 1:1.'))
    'mouse_keyboard_data_queue' = @('Kolejka danych myszy i klawiatury', (U 'Zmniejsza bufory wej\u015bcia dla szybszej obs\u0142ugi sterowania.'))
    'fast_keyboard_repeat' = @('Szybkie powtarzanie klawiszy', (U 'Najkr\u00f3tsze op\u00f3\u017anienie i najszybsze tempo powtarzania klawiszy.'))
    'disable_sticky_filter_toggle_keys' = @((U 'Wy\u0142\u0105cz klawisze trwa\u0142e i filtru'), (U 'Koniec okienek u\u0142atwie\u0144 dost\u0119pu po wielokrotnym wci\u015bni\u0119ciu Shift w grach.'))
    'disable_nagles_algorithm' = @((U 'Wy\u0142\u0105cz algorytm Nagle''a'), (U 'Ma\u0142e pakiety s\u0105 wysy\u0142ane od razu, ni\u017csze op\u00f3\u017anienie w grach online.'))
    'disable_network_throttling' = @((U 'Wy\u0142\u0105cz d\u0142awienie sieci'), (U 'Usuwa multimedialny limit d\u0142awienia sieci.'))
    'optimize_tcp_stack' = @('Optymalizuj stos TCP', (U 'Dostraja auto-tuning, RSS, heurystyk\u0119 i znaczniki czasu.'))
    'disable_adapter_power_saving' = @((U 'Wy\u0142\u0105cz oszcz\u0119dzanie energii karty sieciowej'), (U 'Karty sieciowe nie usypiaj\u0105 i nie obni\u017caj\u0105 pr\u0119dko\u015bci.'))
    'disable_interrupt_moderation' = @((U 'Wy\u0142\u0105cz moderacj\u0119 przerwa\u0144'), (U 'Ni\u017csze op\u00f3\u017anienie sieci kosztem nieco wi\u0119kszego u\u017cycia CPU.'))
    'disable_large_send_offload' = @((U 'Wy\u0142\u0105cz Large Send Offload'), (U 'Naprawia skoki op\u00f3\u017anie\u0144 na niekt\u00f3rych sterownikach sieciowych.'))
    'remove_qos_bandwidth_reserve' = @((U 'Usu\u0144 rezerw\u0119 pasma QoS'), 'Zwalnia pasmo rezerwowane przez Windows dla QoS.')
    'disable_delivery_optimization_p2p' = @((U 'Wy\u0142\u0105cz optymalizacj\u0119 dostarczania P2P'), (U 'Windows przestaje wysy\u0142a\u0107 aktualizacje innym komputerom.'))
    'set_dns_server' = @('Ustaw serwer DNS', (U 'Naci\u015bnij Spacj\u0119, aby wybra\u0107 dostawc\u0119 DNS z listy. Ping do ka\u017cdego jest mierzony.'))
    'flush_dns_arp_cache' = @((U 'Wyczy\u015b\u0107 pami\u0119\u0107 DNS i ARP'), 'Usuwa nieaktualne wpisy DNS i ARP.')
    'disable_telemetry' = @((U 'Wy\u0142\u0105cz telemetri\u0119'), (U 'Ustawia telemetri\u0119 na minimum i wy\u0142\u0105cza us\u0142ugi \u015bledz\u0105ce.'))
    'disable_telemetry_tasks' = @((U 'Wy\u0142\u0105cz zadania telemetrii'), (U 'Wy\u0142\u0105cza CEIP, Compatibility Appraiser i zadania diagnostyczne.'))
    'disable_advertising_id' = @((U 'Wy\u0142\u0105cz identyfikator reklamowy'), (U 'Aplikacje nie mog\u0105 u\u017cywa\u0107 Twojego identyfikatora reklamowego.'))
    'disable_activity_history' = @((U 'Wy\u0142\u0105cz histori\u0119 aktywno\u015bci'), (U 'Windows nie zbiera i nie wysy\u0142a historii aktywno\u015bci.'))
    'disable_bing_in_start_search' = @((U 'Wy\u0142\u0105cz Bing w wyszukiwaniu Start'), 'Wyszukiwanie w menu Start pokazuje tylko wyniki lokalne.')
    'disable_copilot_recall' = @((U 'Wy\u0142\u0105cz Copilot i Recall'), (U 'Wy\u0142\u0105cza Windows Copilot i zrzuty ekranu Recall.'))
    'disable_error_reporting' = @((U 'Wy\u0142\u0105cz raportowanie b\u0142\u0119d\u00f3w'), (U 'Raporty o awariach nie s\u0105 wysy\u0142ane do Microsoftu.'))
    'disable_feedback_prompts' = @((U 'Wy\u0142\u0105cz pro\u015bby o opini\u0119'), (U 'Windows nigdy nie prosi o opini\u0119.'))
    'disable_location_tracking' = @((U 'Wy\u0142\u0105cz \u015bledzenie lokalizacji'), (U 'Wy\u0142\u0105cza us\u0142ugi lokalizacji w ca\u0142ym systemie.'))
    'performance_visual_effects' = @((U 'Efekty wizualne: wydajno\u015b\u0107'), (U 'Wy\u0142\u0105cza animacje, zachowuj\u0105c wyg\u0142adzanie czcionek i miniatury.'))
    'disable_transparency' = @((U 'Wy\u0142\u0105cz przezroczysto\u015b\u0107'), (U 'Wy\u0142\u0105cza efekty akrylu i rozmycia.'))
    'disable_background_apps' = @((U 'Wy\u0142\u0105cz aplikacje w tle'), (U 'Aplikacje ze Sklepu nie dzia\u0142aj\u0105 w tle.'))
    'remove_startup_delay' = @((U 'Usu\u0144 op\u00f3\u017anienie autostartu'), (U 'Aplikacje z autostartu uruchamiaj\u0105 si\u0119 od razu po zalogowaniu.'))
    'instant_menus' = @('Natychmiastowe menu', (U 'Usuwa op\u00f3\u017anienie menu i przyspiesza zamykanie systemu.'))
    'disable_memory_compression' = @((U 'Wy\u0142\u0105cz kompresj\u0119 pami\u0119ci'), (U 'Mniejsze obci\u0105\u017cenie CPU. Najlepiej przy 16 GB RAM lub wi\u0119cej.'))
    'keep_kernel_in_ram' = @((U 'Trzymaj j\u0105dro w RAM'), (U 'Sterowniki i j\u0105dro nie s\u0105 przenoszone do pliku stronicowania.'))
    'disable_sysmain_superfetch' = @((U 'Wy\u0142\u0105cz SysMain (Superfetch)'), (U 'Mniej aktywno\u015bci dysku. Zalecane przy dyskach SSD.'))
    'disable_search_indexing' = @((U 'Wy\u0142\u0105cz indeksowanie wyszukiwania'), (U 'Zatrzymuje indeksowanie plik\u00f3w w tle. Wyszukiwanie dzia\u0142a wolniej.'))
    'ntfs_optimizations' = @('Optymalizacje NTFS', (U 'Wy\u0142\u0105cza znaczniki ostatniego dost\u0119pu i kr\u00f3tkie nazwy 8.3.'))
    'disable_unneeded_services' = @((U 'Wy\u0142\u0105cz zb\u0119dne us\u0142ugi'), 'Faks, Rejestr zdalny, Mapy, Tryb demo, Insider i inne.')
    'disable_tips_suggestions' = @((U 'Wy\u0142\u0105cz porady i sugestie'), 'Usuwa reklamy, sugerowane aplikacje i ciche instalacje aplikacji.')
    'disable_widgets' = @((U 'Wy\u0142\u0105cz wid\u017cety'), (U 'Usuwa tablic\u0119 wid\u017cet\u00f3w i jej proces w tle.'))
    'classic_context_menu' = @('Klasyczne menu kontekstowe', (U 'Przywraca pe\u0142ne menu prawego przycisku myszy w Windows 11.'))
    'show_file_extensions' = @((U 'Poka\u017c rozszerzenia plik\u00f3w'), (U 'Eksplorator zawsze pokazuje rozszerzenia plik\u00f3w.'))
    'disable_edge_background_running' = @((U 'Wy\u0142\u0105cz Edge w tle'), (U 'Wy\u0142\u0105cza Startup Boost i tryb pracy w tle przegl\u0105darki Edge.'))
    'clean_temp_files' = @((U 'Wyczy\u015b\u0107 pliki tymczasowe'), (U 'Usuwa pliki tymczasowe u\u017cytkownika i systemu.'))
    'clear_shader_caches' = @((U 'Wyczy\u015b\u0107 pami\u0119\u0107 shader\u00f3w'), (U 'Czy\u015bci pami\u0119\u0107 shader\u00f3w DirectX, NVIDIA i AMD.'))
    'clear_windows_update_cache' = @((U 'Wyczy\u015b\u0107 pami\u0119\u0107 Windows Update'), 'Usuwa pobrane pliki aktualizacji.')
    'empty_recycle_bin' = @((U 'Opr\u00f3\u017cnij kosz'), (U 'Trwale usuwa ca\u0142\u0105 zawarto\u015b\u0107 kosza.'))
    'dism_component_cleanup' = @((U 'Czyszczenie komponent\u00f3w DISM'), (U 'Zmniejsza folder WinSxS. Mo\u017ce potrwa\u0107 kilka minut.'))
    'remove_bloatware_apps' = @((U 'Usu\u0144 zb\u0119dne aplikacje'), (U 'Wiadomo\u015bci, Pogoda, Pasjans, Clipchamp, Porady, Centrum opinii i inne.'))
    'remove_xbox_apps' = @((U 'Usu\u0144 aplikacje Xbox'), (U 'Usuwa aplikacj\u0119 Xbox i nak\u0142adki. Psuje Game Pass.'))
    'uninstall_onedrive' = @('Odinstaluj OneDrive', (U 'Usuwa OneDrive. Zsynchronizowane pliki zostaj\u0105 na komputerze.'))
}

$TagPl = @(
    ,@('-DISK USAGE', (U '-U\u017bYCIE DYSKU'))
    ,@('+DISK SPEED', '+SZYBKI DYSK')
    ,@('-CPU USAGE', (U '-U\u017bYCIE CPU'))
    ,@('+DNS SPEED', '+SZYBKI DNS')
    ,@('+UI SPEED', '+SZYBKI UI')
    ,@('+1% LOWS', '+1% LOW')
    ,@('NO POPUPS', 'BEZ OKIENEK')
    ,@('-STUTTER', (U '-ZACI\u0118CIA'))
    ,@('+STABILITY', (U '+STABILNO\u015a\u0106'))
    ,@('-LATENCY', (U '-OP\u00d3\u0179NIENIE'))
    ,@('-SECURITY', '-OCHRONA')
    ,@('+SECURITY', '+OCHRONA')
    ,@('+PRIVACY', (U '+PRYWATNO\u015a\u0106'))
    ,@('+RESPONSE', '+REAKCJA')
    ,@('+BANDWIDTH', '+PASMO')
    ,@('-SPIKES', '-SKOKI')
    ,@('+SPEED', (U '+SZYBKO\u015a\u0106'))
    ,@('+DISK', '+DYSK')
    ,@('+BOOT', '+START')
    ,@('+AIM', (U '+CELNO\u015a\u0106'))
    ,@('SAFE', 'BEZPIECZNE')
    ,@('FIX', 'NAPRAWA')
)

function Tr {
    param([string]$K)
    $s = $K
    if ($script:Lang -eq 'pl' -and $K) {
        $m = [regex]::Match($K, '^(\s*)(.*?)(\s*)$')
        $v = $PL[$m.Groups[2].Value]
        if ($null -ne $v) { $s = $m.Groups[1].Value + $v + $m.Groups[3].Value }
    }
    if ($args.Count) { try { $s -f $args } catch { $s } } else { $s }
}

$script:Lang = 'en'
$savedLang = (Get-ItemProperty -Path 'HKCU:\Software\CodeOpt' -Name 'Language').Language
if ($savedLang -in 'en', 'pl') { $script:Lang = $savedLang }
elseif ((Get-UICulture).TwoLetterISOLanguageName -eq 'pl' -or (Get-Culture).TwoLetterISOLanguageName -eq 'pl') { $script:Lang = 'pl' }
if ($Cli.Lang -in 'en', 'pl') { $script:Lang = $Cli.Lang }


if ($Cli.Help -or $Cli.Bad) {
    if ($Cli.Bad) { Write-Host ''; Write-Host ('  ' + (Tr $Cli.Bad[0] $Cli.Bad[1])) -ForegroundColor Red }
    @(
        '',
        '  CodeOpt - Windows Tweaks & Optimizer',
        '',
        '  Usage: .\CodeOpt.ps1 [options]',
        '',
        '    --template <file.toml>   Load a TOML template and preselect its tweaks, DNS and settings',
        '    --lang <en|pl>           Interface language (default: saved choice or Windows language)',
        '    --apply                  Apply the template right away without opening the menu',
        '    --yes                    Skip confirmation and pauses (use with --apply for unattended runs)',
        '    --list                   Print every tweak ID, category and restart requirement',
        '    --help                   Show this help',
        '',
        '  Examples:',
        '    .\CodeOpt.ps1 --template competitive-fps.toml',
        '    .\CodeOpt.ps1 --template competitive-fps.toml --apply --yes',
        '    .\CodeOpt.ps1 --list --lang pl',
        ''
    ) | ForEach-Object { Write-Host (Tr $_) -ForegroundColor Cyan }
    exit
}

if ($Cli.Template) {
    $rp = Resolve-Path -LiteralPath $Cli.Template
    if ($rp) { $Cli.Template = $rp.ProviderPath }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$IsAdmin = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin -and -not $Cli.List) {
    Write-Host ''
    Write-Host (Tr '  CodeOpt needs administrator rights. Requesting elevation...') -ForegroundColor Cyan
    $self = $PSCommandPath
    if (-not $self) {
        $body = $MyInvocation.MyCommand.ScriptBlock
        if ($body -and $body.ToString().Length -gt 1000) {
            $self = Join-Path $env:TEMP 'CodeOpt.ps1'
            [IO.File]::WriteAllText($self, $body.ToString(), [Text.UTF8Encoding]::new($true))
        }
    }
    if ($self) {
        $exe = (Get-Process -Id $PID).Path
        if (-not $exe -or $exe -notmatch '(pwsh|powershell)\.exe$') { $exe = 'powershell.exe' }
        $pass = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$self`"")
        if ($Cli.Template) { $pass += @('--template', "`"$($Cli.Template)`"") }
        if ($Cli.Apply) { $pass += '--apply' }
        if ($Cli.Yes) { $pass += '--yes' }
        $pass += @('--lang', $script:Lang)
        try {
            Start-Process -FilePath $exe -ArgumentList ($pass -join ' ') -Verb RunAs -WorkingDirectory (Get-Location).ProviderPath -ErrorAction Stop
            exit
        } catch {
            Write-Host (Tr '  Elevation was cancelled. CodeOpt cannot apply tweaks without administrator rights.') -ForegroundColor Red
        }
    } else {
        Write-Host (Tr '  Could not relaunch automatically. Open PowerShell as Administrator and run CodeOpt again.') -ForegroundColor Red
    }
    Write-Host (Tr '  Press any key to exit...') -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
    exit
}

$G = @{
    TL = [string][char]0x2554; TR = [string][char]0x2557; BL = [string][char]0x255A; BR = [string][char]0x255D
    H = [string][char]0x2550; V = [string][char]0x2551; L = [string][char]0x2500
    Ptr = [string][char]0x25BA; On = [string][char]0x25A0; Full = [string][char]0x2588; Shade = [string][char]0x2591
    Up = [string][char]0x2191; Dn = [string][char]0x2193; Lf = [string][char]0x2190; Rt = [string][char]0x2192
    Dot = [string][char]0x2022; Ok = [string][char]0x2714; Tri = [string][char]0x25B2; TriD = [string][char]0x25BC
}

$script:Bg = 'Black'
$script:W = 80

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Disable-Svc {
    param([string[]]$Names)
    foreach ($n in $Names) {
        Stop-Service -Name $n -Force -ErrorAction SilentlyContinue
        Set-Service -Name $n -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

function Disable-Tasks {
    param([string[]]$Paths)
    foreach ($p in $Paths) { schtasks.exe /Change /TN $p /Disable 2>$null | Out-Null }
}

function Remove-Apps {
    param([string[]]$Names)
    foreach ($a in $Names) {
        Get-AppxPackage -AllUsers -Name $a | Remove-AppxPackage -AllUsers
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $a | Remove-AppxProvisionedPackage -Online | Out-Null
    }
}

function Set-PowerValue {
    param([string]$Sub, [string]$Setting, [int]$Value)
    powercfg /setacvalueindex scheme_current $Sub $Setting $Value | Out-Null
    powercfg /setdcvalueindex scheme_current $Sub $Setting $Value | Out-Null
    powercfg /setactive scheme_current | Out-Null
}

$Tweaks = [System.Collections.Generic.List[object]]::new()
function T {
    param([string]$Cat, [string]$Name, [string]$Desc, [bool]$Rec, [scriptblock]$Do)
    $Tags = ''
    if ($Desc -match '^\[(.+?)\]\s*(.*)$') { $Tags = $Matches[1]; $Desc = $Matches[2] }
    $Tweaks.Add([pscustomobject]@{ Cat = $Cat; Name = $Name; Desc = $Desc; Tags = $Tags; Fps = ($Tags -match '\+FPS'); Rec = $Rec; Do = $Do; Sel = $false; GMin = 0; GMax = 0; GWhy = ''; Id = ''; Reboot = 'None'; Pick = $false; Opt = $null; GArg = $null })
}

T 'Safety' 'Create System Restore Point' '[SAFE] Creates a restore point so every change can be rolled back from System Restore.' $true {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0
    Checkpoint-Computer -Description 'CodeOpt' -RestorePointType 'MODIFY_SETTINGS'
}
T 'Safety' 'Backup Registry Hives' '[SAFE] Exports HKLM\SYSTEM and HKCU\Software to Documents\CodeOpt-Backup.' $false {
    $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('CodeOpt-Backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    reg.exe export 'HKLM\SYSTEM\CurrentControlSet' "$dir\System.reg" /y | Out-Null
    reg.exe export 'HKCU\Software' "$dir\UserSoftware.reg" /y | Out-Null
    reg.exe export 'HKCU\Control Panel' "$dir\ControlPanel.reg" /y | Out-Null
}

T 'Power' 'Ultimate Performance Plan' '[+FPS +1% LOWS] Unlocks and activates a tuned Ultimate Performance power plan.' $true {
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    $guid = [regex]::Match(($out -join ' '), '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}').Value
    if ($guid) {
        powercfg -changename $guid 'CodeOpt Ultimate' 'Maximum performance plan by CodeOpt' | Out-Null
        powercfg -setactive $guid | Out-Null
    }
    Set-PowerValue 'SUB_PROCESSOR' 'PROCTHROTTLEMIN' 100
    Set-PowerValue 'SUB_DISK' 'DISKIDLE' 0
    Set-PowerValue 'SUB_SLEEP' 'STANDBYIDLE' 0
}
T 'Power' 'Disable Core Parking' '[+FPS -STUTTER] Keeps all CPU cores awake to avoid wake-up latency.' $true {
    Set-PowerValue 'SUB_PROCESSOR' 'CPMINCORES' 100
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583' 'ValueMax' 0
}
T 'Power' 'Disable USB Selective Suspend' '[-INPUT LAG] Prevents USB devices like mice and headsets from sleeping.' $true {
    Set-PowerValue '2a737441-1930-4402-8d77-b2bebba308a3' '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0
}
T 'Power' 'Disable PCIe Link State Power Saving' '[+FPS -STUTTER] Turns off ASPM so GPU and NVMe links stay at full speed.' $true {
    Set-PowerValue 'SUB_PCIEXPRESS' 'ASPM' 0
}
T 'Power' 'Disable Power Throttling' '[+FPS] Stops Windows from throttling background processes.' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
}
T 'Power' 'Disable Hibernation' '[+DISK] Turns off hibernation and deletes hiberfil.sys to free disk space.' $true {
    powercfg -h off | Out-Null
}
T 'Power' 'Disable Fast Startup' '[+STABILITY] Forces a clean boot each time, fixing driver and uptime issues.' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
}

T 'Gaming' 'Enable Game Mode' '[+FPS] Lets Windows prioritize the game and pause background updates.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
}
T 'Gaming' 'Disable Game Bar & Game DVR' '[+FPS -STUTTER] Removes background recording and the Xbox Game Bar overlay.' $true {
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'ShowStartupPanel' 0
}
T 'Gaming' 'Disable Fullscreen Optimizations' '[+FPS -INPUT LAG] Uses true exclusive fullscreen for lower input latency.' $true {
    $p = 'HKCU:\System\GameConfigStore'
    Set-Reg $p 'GameDVR_FSEBehaviorMode' 2
    Set-Reg $p 'GameDVR_FSEBehavior' 2
    Set-Reg $p 'GameDVR_HonorUserFSEBehaviorMode' 1
    Set-Reg $p 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
    Set-Reg $p 'GameDVR_EFSEFeatureFlags' 0
}
T 'Gaming' 'Optimizations for Windowed Games' '[+FPS -INPUT LAG] Enables flip-model presentation for borderless and windowed games.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'SwapEffectUpgradeEnable=1;' 'String'
}
T 'Gaming' 'Hardware-Accelerated GPU Scheduling' '[+FPS -LATENCY] Lets the GPU manage its own memory scheduling. Needs a supported GPU.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
}
T 'Gaming' 'MMCSS Game Priority' '[+FPS +1% LOWS] Raises GPU and CPU scheduling priority for games.' $true {
    $p = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $p 'GPU Priority' 8
    Set-Reg $p 'Priority' 6
    Set-Reg $p 'Scheduling Category' 'High' 'String'
    Set-Reg $p 'SFIO Priority' 'High' 'String'
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
}
T 'Gaming' 'CPU Priority Separation' '[+FPS -INPUT LAG] Short, variable quantums favoring the foreground app (0x26).' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
}
T 'Gaming' 'Global Timer Resolution' '[-INPUT LAG +1% LOWS] Allows high timer resolution requests to apply system-wide.' $true {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1
}
T 'Gaming' 'Disable Dynamic Tick' '[-LATENCY] Keeps the system timer ticking at a constant rate.' $false {
    bcdedit /set disabledynamictick yes | Out-Null
}
T 'Gaming' 'Disable HPET Platform Clock' '[+FPS -LATENCY] Removes forced HPET usage for a faster timer source.' $false {
    bcdedit /deletevalue useplatformclock | Out-Null
    bcdedit /set useplatformtick yes | Out-Null
}
T 'Gaming' 'Disable Multiplane Overlay (MPO)' '[-STUTTER] Fixes flicker and stutter on some NVIDIA and multi-monitor setups.' $false {
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
}
T 'Gaming' 'Disable VBS & Memory Integrity' '[+FPS -SECURITY] Gains FPS on some CPUs but lowers system security.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
}
T 'Gaming' 'Disable NVIDIA Telemetry' '[+PRIVACY -CPU USAGE] Disables NVIDIA telemetry tasks, service and opt-in.' $true {
    Get-ScheduledTask -TaskName 'NvTmRep*' | Disable-ScheduledTask | Out-Null
    Get-ScheduledTask -TaskName 'NvTmMon*' | Disable-ScheduledTask | Out-Null
    Disable-Svc @('NvTelemetryContainer')
    Set-Reg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'OptInOrOutPreference' 0
}

T 'Input' 'Disable Mouse Acceleration' '[+AIM] Turns off Enhance Pointer Precision for 1:1 aim.' $true {
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
}
T 'Input' 'Mouse & Keyboard Data Queue' '[-INPUT LAG] Lowers input buffer sizes for faster input processing.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters' 'MouseDataQueueSize' 20
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters' 'KeyboardDataQueueSize' 20
}
T 'Input' 'Fast Keyboard Repeat' '[+RESPONSE] Shortest repeat delay and fastest repeat rate.' $true {
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
}
T 'Input' 'Disable Sticky/Filter/Toggle Keys' '[NO POPUPS] Stops accessibility pop-ups when pressing Shift repeatedly in games.' $true {
    Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'
    Set-Reg 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' 'String'
    Set-Reg 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String'
}

T 'Network' "Disable Nagle's Algorithm" '[-PING] Sends small packets immediately for lower online latency.' $true {
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1
        Set-Reg $_.PSPath 'TCPNoDelay' 1
        Set-Reg $_.PSPath 'TcpDelAckTicks' 0
    }
}
T 'Network' 'Disable Network Throttling' '[-PING] Removes the multimedia network throttling limit.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
}
T 'Network' 'Optimize TCP Stack' '[-PING +SPEED] Tunes auto-tuning, RSS, heuristics and timestamps.' $true {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set heuristics disabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null
    netsh int tcp set global initialRto=2000 | Out-Null
    netsh int tcp set global nonsackrttresiliency=disabled | Out-Null
}
T 'Network' 'Disable Adapter Power Saving' '[-PING -SPIKES] Stops network adapters from sleeping or reducing speed.' $true {
    Get-NetAdapter -Physical | ForEach-Object {
        Disable-NetAdapterPowerManagement -Name $_.Name -NoRestart
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword '*EEE' -RegistryValue 0 -NoRestart
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword 'EnableGreenEthernet' -RegistryValue 0 -NoRestart
    }
}
T 'Network' 'Disable Interrupt Moderation' '[-PING] Lower network latency at the cost of slightly more CPU usage.' $false {
    Get-NetAdapter -Physical | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -RegistryKeyword '*InterruptModeration' -RegistryValue 0 -NoRestart
    }
}
T 'Network' 'Disable Large Send Offload' '[-PING -SPIKES] Fixes latency spikes on some network drivers.' $false {
    Get-NetAdapter -Physical | ForEach-Object { Disable-NetAdapterLso -Name $_.Name -NoRestart }
}
T 'Network' 'Remove QoS Bandwidth Reserve' '[+BANDWIDTH] Frees the bandwidth Windows reserves for QoS.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched' 'NonBestEffortLimit' 0
}
T 'Network' 'Disable Delivery Optimization P2P' '[+BANDWIDTH] Stops uploading Windows updates to other PCs.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0
}
T 'Network' 'Set DNS Server' '[+DNS SPEED] Press Space to pick a DNS provider from the list. Ping to each one is measured.' $false {
    param($t)
    $o = Get-DnsChoice $t
    $srv = @(@($o.V4) + @($o.V6))
    foreach ($na in @(Get-NetAdapter -Physical | Where-Object Status -eq 'Up')) {
        if ($o.Id -eq 'auto') { Set-DnsClientServerAddress -InterfaceIndex $na.ifIndex -ResetServerAddresses }
        else { Set-DnsClientServerAddress -InterfaceIndex $na.ifIndex -ServerAddresses $srv }
    }
    if ($o.Doh -and (Get-Command Add-DnsClientDohServerAddress)) {
        foreach ($ip in $srv) {
            if (Get-DnsClientDohServerAddress -ServerAddress $ip) { Set-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $o.Doh -AllowFallbackToUdp $true -AutoUpgrade $true }
            else { Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $o.Doh -AllowFallbackToUdp $true -AutoUpgrade $true }
        }
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' 'EnableAutoDoh' 2
    }
    Clear-DnsClientCache
}
T 'Network' 'Flush DNS & ARP Cache' '[FIX] Clears stale DNS and ARP entries.' $true {
    ipconfig /flushdns | Out-Null
    netsh interface ip delete arpcache | Out-Null
}

T 'Privacy' 'Disable Telemetry' '[+PRIVACY -CPU USAGE] Sets telemetry to minimum and disables tracking services.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
    Disable-Svc @('DiagTrack', 'dmwappushservice')
}
T 'Privacy' 'Disable Telemetry Tasks' '[+PRIVACY -STUTTER] Disables CEIP, Compatibility Appraiser and diagnostic tasks.' $true {
    Disable-Tasks @(
        '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
        '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
        '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
        '\Microsoft\Windows\Autochk\Proxy',
        '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
        '\Microsoft\Windows\Feedback\Siuf\DmClient',
        '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
    )
}
T 'Privacy' 'Disable Advertising ID' '[+PRIVACY] Stops apps from using your advertising ID.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
}
T 'Privacy' 'Disable Activity History' '[+PRIVACY] Stops Windows from collecting and uploading activity history.' $true {
    $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
    Set-Reg $p 'EnableActivityFeed' 0
    Set-Reg $p 'PublishUserActivities' 0
    Set-Reg $p 'UploadUserActivities' 0
}
T 'Privacy' 'Disable Bing in Start Search' '[+PRIVACY +UI SPEED] Start menu search only shows local results.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
    Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
}
T 'Privacy' 'Disable Copilot & Recall' '[+PRIVACY +RAM] Turns off Windows Copilot and Recall snapshots.' $true {
    Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'AllowRecallEnablement' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
}
T 'Privacy' 'Disable Error Reporting' '[+PRIVACY] Stops sending crash reports to Microsoft.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
    Disable-Svc @('WerSvc')
}
T 'Privacy' 'Disable Feedback Prompts' '[+PRIVACY] Never ask for Windows feedback.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
}
T 'Privacy' 'Disable Location Tracking' '[+PRIVACY] Turns off system-wide location services.' $false {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1
    Disable-Svc @('lfsvc')
}

T 'System' 'Performance Visual Effects' '[+FPS +UI SPEED] Disables animations while keeping smooth fonts and thumbnails.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 3
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) 'Binary'
    Set-Reg 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0
}
T 'System' 'Disable Transparency' '[+FPS +UI SPEED] Turns off acrylic and blur effects.' $false {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
}
T 'System' 'Disable Background Apps' '[+FPS +RAM] Stops Store apps from running in the background.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
}
T 'System' 'Remove Startup Delay' '[+BOOT] Launches startup apps immediately after login.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
}
T 'System' 'Instant Menus' '[+UI SPEED] Removes the menu show delay and speeds up shutdown.' $true {
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'WaitToKillAppTimeout' '2000' 'String'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'HungAppTimeout' '1000' 'String'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'AutoEndTasks' '1' 'String'
}
T 'System' 'Disable Memory Compression' '[+FPS -CPU USAGE] Less CPU overhead. Best with 16 GB RAM or more.' $false {
    Disable-MMAgent -MemoryCompression
}
T 'System' 'Keep Kernel in RAM' '[-STUTTER] Prevents drivers and kernel from being paged to disk.' $false {
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'DisablePagingExecutive' 1
}
T 'System' 'Disable SysMain (Superfetch)' '[-DISK USAGE] Reduces disk activity. Recommended on SSD systems.' $false {
    Disable-Svc @('SysMain')
}
T 'System' 'Disable Search Indexing' '[-DISK USAGE -CPU USAGE] Stops background file indexing. Search gets slower.' $false {
    Disable-Svc @('WSearch')
}
T 'System' 'NTFS Optimizations' '[+DISK SPEED] Disables last-access timestamps and 8.3 short names.' $true {
    fsutil behavior set disablelastaccess 1 | Out-Null
    fsutil behavior set disable8dot3 1 | Out-Null
}
T 'System' 'Disable Unneeded Services' '[+RAM] Fax, Remote Registry, Maps, Retail Demo, Insider and others.' $true {
    Disable-Svc @('Fax', 'RemoteRegistry', 'MapsBroker', 'RetailDemo', 'WMPNetworkSvc', 'wisvc', 'WpcMonSvc')
}
T 'System' 'Disable Tips & Suggestions' '[+PRIVACY] Removes ads, suggested apps and silent app installs.' $true {
    $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    foreach ($n in @('SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled', 'SoftLandingEnabled', 'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'PreInstalledAppsEnabled', 'OemPreInstalledAppsEnabled')) { Set-Reg $p $n 0 }
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
}
T 'System' 'Disable Widgets' '[+RAM] Removes the Widgets board and its background process.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
}
T 'System' 'Classic Context Menu' '[+UI SPEED] Restores the full right-click menu on Windows 11.' $false {
    reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve | Out-Null
}
T 'System' 'Show File Extensions' '[+SECURITY] Always shows file extensions in Explorer.' $true {
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
}
T 'System' 'Disable Edge Background Running' '[+RAM +BOOT] Stops Edge Startup Boost and background mode.' $true {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0
}

T 'Cleanup' 'Clean Temp Files' '[+DISK] Deletes user and system temporary files.' $true {
    Remove-Item -Path "$env:TEMP\*", "$env:windir\Temp\*" -Recurse -Force
}
T 'Cleanup' 'Clear Shader Caches' '[+DISK FIX] Clears DirectX, NVIDIA and AMD shader caches.' $false {
    Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*", "$env:LOCALAPPDATA\NVIDIA\DXCache\*", "$env:LOCALAPPDATA\NVIDIA\GLCache\*", "$env:LOCALAPPDATA\AMD\DxCache\*" -Recurse -Force
}
T 'Cleanup' 'Clear Windows Update Cache' '[+DISK] Removes downloaded update files.' $true {
    Stop-Service -Name wuauserv, bits -Force
    Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force
    Start-Service -Name wuauserv, bits
}
T 'Cleanup' 'Empty Recycle Bin' '[+DISK] Permanently deletes everything in the Recycle Bin.' $false {
    Clear-RecycleBin -Force
}
T 'Cleanup' 'DISM Component Cleanup' '[+DISK] Shrinks the WinSxS folder. Can take several minutes.' $false {
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart | Out-Null
}

T 'Debloat' 'Remove Bloatware Apps' '[+RAM +DISK] News, Weather, Solitaire, Clipchamp, Tips, Feedback Hub and more.' $false {
    Remove-Apps @(
        'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.Getstarted',
        'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.People', 'Microsoft.WindowsFeedbackHub',
        'Microsoft.ZuneVideo', 'Microsoft.MicrosoftOfficeHub', 'Clipchamp.Clipchamp', 'Microsoft.Todos',
        'Microsoft.PowerAutomateDesktop', 'Microsoft.WindowsMaps', 'Microsoft.549981C3F5F10',
        'MicrosoftTeams', 'MSTeams', 'Microsoft.BingSearch', 'Microsoft.MixedReality.Portal', 'Microsoft.SkypeApp'
    )
}
T 'Debloat' 'Remove Xbox Apps' '[+RAM] Removes Xbox app and overlays. Breaks Game Pass.' $false {
    Remove-Apps @('Microsoft.XboxApp', 'Microsoft.GamingApp', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxSpeechToTextOverlay')
}
T 'Debloat' 'Uninstall OneDrive' '[+RAM +BOOT] Removes OneDrive. Synced files stay on your PC.' $false {
    Stop-Process -Name OneDrive -Force
    $setup = "$env:SystemRoot\System32\OneDriveSetup.exe"
    if (-not (Test-Path $setup)) { $setup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" }
    if (Test-Path $setup) { Start-Process $setup -ArgumentList '/uninstall' -Wait }
    else { winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements | Out-Null }
}

$Cats = @('Safety', 'Power', 'Gaming', 'Input', 'Network', 'Privacy', 'System', 'Cleanup', 'Debloat')

function New-Dns { param($Id, $Name, $V4, $V6, $Doh, $Note) @{ Id = $Id; Name = $Name; V4 = @($V4); V6 = @($V6); Doh = $Doh; Note = $Note } }
$Dns = @(
    (New-Dns 'cloudflare' 'Cloudflare' @('1.1.1.1', '1.0.0.1') @('2606:4700:4700::1111', '2606:4700:4700::1001') 'https://cloudflare-dns.com/dns-query' 'Fast anycast, privacy-first'),
    (New-Dns 'cloudflare_malware' 'Cloudflare Malware' @('1.1.1.2', '1.0.0.2') @('2606:4700:4700::1112', '2606:4700:4700::1002') 'https://security.cloudflare-dns.com/dns-query' 'Blocks malware'),
    (New-Dns 'cloudflare_family' 'Cloudflare Family' @('1.1.1.3', '1.0.0.3') @('2606:4700:4700::1113', '2606:4700:4700::1003') 'https://family.cloudflare-dns.com/dns-query' 'Blocks malware and adult content'),
    (New-Dns 'google' 'Google' @('8.8.8.8', '8.8.4.4') @('2001:4860:4860::8888', '2001:4860:4860::8844') 'https://dns.google/dns-query' 'Very reliable, huge network'),
    (New-Dns 'quad9' 'Quad9' @('9.9.9.9', '149.112.112.112') @('2620:fe::fe', '2620:fe::9') 'https://dns.quad9.net/dns-query' 'Blocks malware, Swiss privacy'),
    (New-Dns 'opendns' 'OpenDNS' @('208.67.222.222', '208.67.220.220') @('2620:119:35::35', '2620:119:53::53') 'https://doh.opendns.com/dns-query' 'Cisco, phishing protection'),
    (New-Dns 'opendns_family' 'OpenDNS FamilyShield' @('208.67.222.123', '208.67.220.123') @() 'https://doh.familyshield.opendns.com/dns-query' 'Blocks adult content'),
    (New-Dns 'adguard' 'AdGuard' @('94.140.14.14', '94.140.15.15') @('2a10:50c0::ad1:ff', '2a10:50c0::ad2:ff') 'https://dns.adguard-dns.com/dns-query' 'Blocks ads and trackers'),
    (New-Dns 'adguard_family' 'AdGuard Family' @('94.140.14.15', '94.140.15.16') @('2a10:50c0::bad1:ff', '2a10:50c0::bad2:ff') 'https://family.adguard-dns.com/dns-query' 'Ads, trackers and adult content'),
    (New-Dns 'adguard_unfiltered' 'AdGuard Unfiltered' @('94.140.14.140', '94.140.14.141') @('2a10:50c0::1:ff', '2a10:50c0::2:ff') 'https://unfiltered.adguard-dns.com/dns-query' 'No filtering'),
    (New-Dns 'controld' 'Control D' @('76.76.2.0', '76.76.10.0') @('2606:1a40::', '2606:1a40:1::') 'https://freedns.controld.com/p0' 'No filtering, low latency'),
    (New-Dns 'controld_malware' 'Control D Malware' @('76.76.2.1', '76.76.10.1') @('2606:1a40::1', '2606:1a40:1::1') 'https://freedns.controld.com/p1' 'Blocks malware'),
    (New-Dns 'cleanbrowsing' 'CleanBrowsing Security' @('185.228.168.9', '185.228.169.9') @('2a0d:2a00:1::2', '2a0d:2a00:2::2') 'https://doh.cleanbrowsing.org/doh/security-filter/' 'Blocks malware and phishing'),
    (New-Dns 'cleanbrowsing_family' 'CleanBrowsing Family' @('185.228.168.168', '185.228.169.168') @('2a0d:2a00:1::', '2a0d:2a00:2::') 'https://doh.cleanbrowsing.org/doh/family-filter/' 'Strict family filter'),
    (New-Dns 'comodo' 'Comodo Secure' @('8.26.56.26', '8.20.247.20') @() '' 'Blocks malicious sites'),
    (New-Dns 'auto' 'Automatic (DHCP)' @() @() '' 'Reset to your router or ISP DNS'),
    (New-Dns 'custom' 'Custom...' @() @() '' 'Enter your own server addresses')
)

$RebootMap = @{
    'Restart' = @(
        'Disable Power Throttling', 'Hardware-Accelerated GPU Scheduling', 'MMCSS Game Priority', 'Global Timer Resolution',
        'Disable Dynamic Tick', 'Disable HPET Platform Clock', 'Disable Multiplane Overlay (MPO)', 'Disable VBS & Memory Integrity',
        'Mouse & Keyboard Data Queue', "Disable Nagle's Algorithm", 'Disable Network Throttling', 'Disable Adapter Power Saving',
        'Disable Interrupt Moderation', 'Disable Large Send Offload', 'Remove QoS Bandwidth Reserve', 'Disable Telemetry',
        'Disable Location Tracking', 'Disable Memory Compression', 'Keep Kernel in RAM', 'NTFS Optimizations'
    )
    'Sign out' = @(
        'Disable Game Bar & Game DVR', 'Disable Fullscreen Optimizations', 'Disable Mouse Acceleration', 'Fast Keyboard Repeat',
        'Disable Sticky/Filter/Toggle Keys', 'Disable Activity History', 'Disable Bing in Start Search', 'Disable Copilot & Recall',
        'Performance Visual Effects', 'Disable Background Apps', 'Instant Menus', 'Disable Tips & Suggestions',
        'Disable Widgets', 'Classic Context Menu'
    )
}

foreach ($t in $Tweaks) {
    $t.Id = ($t.Name.ToLower() -replace "'", '' -replace '[^a-z0-9]+', '_').Trim('_')
    foreach ($rk in $RebootMap.Keys) { if ($RebootMap[$rk] -contains $t.Name) { $t.Reboot = $rk } }
    if ($t.Name -eq 'Set DNS Server') { $t.Pick = $true }
}

function Find-Tweak { param([string]$Id) $x = ($Id.Trim().ToLower() -replace '[^a-z0-9]+', '_').Trim('_'); $Tweaks | Where-Object { $_.Id -eq $x } | Select-Object -First 1 }
function Get-DnsChoice { param($t) if ($t.Opt) { $t.Opt } else { $Dns[0] } }
function Get-TweakBase { param($t) if ($script:Lang -eq 'pl' -and $TweakPl[$t.Id]) { $TweakPl[$t.Id][0] } else { $t.Name } }
function Get-TweakDesc { param($t) if ($script:Lang -eq 'pl' -and $TweakPl[$t.Id]) { $TweakPl[$t.Id][1] } else { $t.Desc } }
function Get-TweakName { param($t) if ($t.Pick -and $t.Sel) { (Get-TweakBase $t) + ': ' + (Tr (Get-DnsChoice $t).Name) } else { Get-TweakBase $t } }
function Get-TagText {
    param([string]$Tags)
    if ($script:Lang -ne 'pl' -or -not $Tags) { return $Tags }
    $s = $Tags
    foreach ($p in $TagPl) { $s = $s -replace ('(?<![^\s])' + [regex]::Escape($p[0]) + '(?![^\s])'), $p[1] }
    $s
}
function Update-Layout {
    $script:NameW = 38; $script:TagW = 23
    foreach ($t in $Tweaks) {
        $n = (Get-TweakBase $t).Length
        if ($t.Pick) { $n += 24 }
        if ($n + 1 -gt $script:NameW) { $script:NameW = $n + 1 }
        $g = (Get-TagText $t.Tags).Length
        if ($g + 1 -gt $script:TagW) { $script:TagW = $g + 1 }
    }
    $script:NameW = [Math]::Min(48, $script:NameW)
}
function Test-Ip { param([string]$A) $x = $null; [System.Net.IPAddress]::TryParse($A, [ref]$x) }

if ($Cli.List) {
    Write-Host ''
    Write-Host ('  {0,-40} {1,-15} {2,-13} {3}' -f 'ID', (Tr 'CATEGORY'), (Tr 'APPLY'), (Tr 'RECOMMENDED')) -ForegroundColor Cyan
    foreach ($t in $Tweaks) {
        $ap = if ($t.Reboot -eq 'None') { Tr 'instant' } else { Tr $t.Reboot.ToLower() }
        Write-Host ('  {0,-40} {1,-15} {2,-13} {3}' -f $t.Id, (Tr $t.Cat), $ap, $(if ($t.Rec) { Tr 'yes' } else { '' })) -ForegroundColor Gray
    }
    Write-Host ''
    Write-Host ((Tr '  DNS providers: ') + (($Dns | ForEach-Object { $_.Id }) -join ', ')) -ForegroundColor DarkCyan
    Write-Host ''
    exit
}

$os = ((Get-CimInstance Win32_OperatingSystem).Caption -replace 'Microsoft ', '')

function Get-GpuScore {
    param([string]$N, [double]$V)
    $s = 0
    $t = @(
        @(10, 'RTX 5090|RTX 5080|RTX 4090'),
        @(9, 'RTX 4080|RTX 5070 Ti|RX 7900|RX 9070'),
        @(8, 'RTX 5070|RTX 4070|RTX 3090|RTX 3080|RX 7800|RX 69\d0|RX 6800|Arc B7'),
        @(7, 'RTX 5060|RTX 4060|RTX 3070|RTX 2080|RX 7700|RX 7600|RX 67\d0|RX 9060|Arc A7|Arc B5'),
        @(6, 'RTX 3060|RTX 2070|RTX 2060|GTX 1080|RX 66\d0|RX 6600|RX 5700|Arc A5'),
        @(5, 'RTX 3050|RTX 2050|GTX 1660|GTX 1070|RX 5600|RX 5500|RX 590|RX 580'),
        @(4, 'GTX 1650|GTX 1060|GTX 980|GTX 970|RX 570|RX 6500|Arc A3|8[89]0M'),
        @(3, 'GTX 1050|GTX 960|RX 560|RX 6400|RX 550|7[6-8]0M|Arc\(TM\) Graphics|Arc Graphics'),
        @(2, 'Iris|Vega|Radeon\(TM\) Graphics|Radeon Graphics|MX\d{3}'),
        @(1, 'UHD|HD Graphics')
    )
    foreach ($r in $t) { if ($N -match $r[1]) { $s = $r[0]; break } }
    if (-not $s) { $s = if ($V -ge 12GB) { 7 } elseif ($V -ge 8GB) { 5 } elseif ($V -ge 4GB) { 3 } else { 2 } }
    if ($N -match 'Laptop|Mobile|Max-Q') { $s = [math]::Max(1, $s - 1) }
    $s
}

function Get-HW {
    $h = @{}
    $p = Get-CimInstance Win32_Processor | Select-Object -First 1
    $n = ([string]$p.Name -replace '\((R|TM)\)', '' -replace '\s+\d+-Core', '' -replace '\s+(CPU|Processor)\b', '' -replace '\s*@.*$', '' -replace '\s+', ' ').Trim()
    $h.Cpu = if ($n.Length -gt 32) { $n.Substring(0, 32) } else { $n }
    $h.Cores = [int]$p.NumberOfCores
    $h.Threads = [int]$p.NumberOfLogicalProcessors
    $h.Clock = [int]$p.MaxClockSpeed
    if ($h.Threads -lt 1) { $h.Threads = 4 }
    if ($h.Clock -lt 1) { $h.Clock = 3000 }
    $cs = [math]::Min(6, $h.Threads * 0.3) + [math]::Min(4, $h.Clock / 1000)
    if ($n -match 'X3D') { $cs += 2 }
    if ($n -match 'Ryzen \d+ (7|8|9)\d{3}|Core Ultra|i\d-1[2-5]\d{3}|Ryzen AI') { $cs += 1 }
    if ($n -match 'i\d-[2-7]\d{3}\b|FX-|Athlon|Celeron|Pentium|Ryzen \d (1|2)\d{3}') { $cs -= 1.5 }
    $h.CpuScore = [math]::Round([math]::Max(1, [math]::Min(10, $cs)), 1)

    $vr = @{}
    Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*' | ForEach-Object {
        $q = $_.'HardwareInformation.qwMemorySize'
        if ($null -eq $q) { $q = $_.'HardwareInformation.MemorySize' }
        if ($q -is [byte[]]) { $q = [BitConverter]::ToUInt64([byte[]](($q + [byte[]]::new(8))[0..7]), 0) }
        if ($_.DriverDesc -and $q) { $vr[[string]$_.DriverDesc] = [double]$q }
    }
    $gs = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic Display|Remote|Virtual|Parsec|Mirage|DisplayLink|Meta' })
    $best = $null; $bs = -1; $h.Vram = 0
    foreach ($g in $gs) {
        $v = if ($vr[[string]$g.Name]) { $vr[[string]$g.Name] } else { [double]([int64]$g.AdapterRAM -band 0xFFFFFFFF) }
        $s = Get-GpuScore $g.Name $v
        if ($s -gt $bs) { $bs = $s; $best = $g; $h.Vram = [math]::Round($v / 1GB) }
    }
    $gn = if ($best) { ([string]$best.Name -replace '\((R|TM)\)', '' -replace '\s+', ' ').Trim() } else { 'Unknown GPU' }
    $h.Gpu = if ($gn.Length -gt 30) { $gn.Substring(0, 30) } else { $gn }
    $h.GpuScore = [math]::Max(1, $bs)
    $h.GpuVendor = if ($gn -match 'NVIDIA|GeForce|RTX|GTX') { 'NVIDIA' } elseif ($gn -match 'AMD|Radeon') { 'AMD' } elseif ($gn -match 'Intel|Arc') { 'Intel' } else { 'Other' }
    $h.IGpu = ($gn -match 'UHD|Iris|HD Graphics|Arc(\(TM\))? Graphics|Radeon(\(TM\))? (\d{3}M )?Graphics|Vega \d+') -or ($h.Vram -lt 1)
    $h.HagsOk = (-not $h.IGpu) -and ($gn -match 'RTX|GTX 1[06]\d0|GTX 16|RX [5-9]\d{3}|Arc (A|B)\d')
    $h.Hz = [int](@(Get-CimInstance Win32_VideoController) | Measure-Object -Property CurrentRefreshRate -Maximum).Maximum

    $h.RamGB = [int][math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $m = @(Get-CimInstance Win32_PhysicalMemory)
    $h.Sticks = $m.Count
    $h.RamMHz = [int]($m | Measure-Object -Property ConfiguredClockSpeed -Maximum).Maximum

    $h.Disk = 'Unknown'
    $dn = (Get-Partition -DriveLetter $env:SystemDrive[0] | Get-Disk).Number
    $pd = Get-PhysicalDisk | Where-Object { [string]$_.DeviceId -eq [string]$dn } | Select-Object -First 1
    if ($pd) { $h.Disk = if ([string]$pd.BusType -eq 'NVMe') { 'NVMe' } elseif ([string]$pd.MediaType -eq 'HDD') { 'HDD' } elseif ([string]$pd.MediaType -eq 'SSD') { 'SSD' } else { [string]$pd.MediaType } }

    $ch = @((Get-CimInstance Win32_SystemEnclosure).ChassisTypes)
    $h.Laptop = [bool](Get-CimInstance Win32_Battery) -or (@($ch | Where-Object { $_ -in 8, 9, 10, 14, 30, 31, 32 }).Count -gt 0)
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard
    $h.Vbs = ($dg.VirtualizationBasedSecurityStatus -eq 2)
    $h.Dvr = ((Get-ItemProperty 'HKCU:\System\GameConfigStore').GameDVR_Enabled -ne 0)

    $cf = 90 + $h.CpuScore * 45
    $gf = 40 + $h.GpuScore * 50
    $b = [math]::Min($cf, $gf)
    if ($h.RamGB -le 8) { $b *= 0.85 }
    if ($h.Sticks -eq 1) { $b *= 0.9 }
    if ($h.Laptop) { $b *= 0.9 }
    $h.Bound = if ($cf -lt $gf) { 'CPU' } else { 'GPU' }
    $h.BaseFps = [int]([math]::Round($b / 5) * 5)
    $h
}

$HW = Get-HW
$script:Base = $HW.BaseFps
$script:BaseSrc = 'est'

function Gn { param($a, $b, $r, $x) $a, $b, $r, $x }

$Gain = @{
    'Ultimate Performance Plan' = { if ($HW.Laptop) { Gn 3 8 'laptop power limits relaxed' } elseif ($HW.CpuScore -lt 6) { Gn 2 5 'CPU clocks held higher' } else { Gn 1 3 'clocks stay boosted' } }
    'Disable Core Parking' = { if ($HW.Threads -le 8) { Gn 2 5 'only {0} threads, parking hurts more' $HW.Threads } else { Gn 1 3 'fewer core wake-ups' } }
    'Disable PCIe Link State Power Saving' = { if ($HW.IGpu) { Gn 0 0 'integrated GPU, no PCIe link to tune' } elseif ($HW.Laptop) { Gn 1 3 'laptop link power saving is aggressive' } else { Gn 0 2 'GPU link stays at full speed' } }
    'Disable Power Throttling' = { if ($HW.Laptop) { Gn 2 5 'laptops throttle background threads hard' } else { Gn 0 2 'small effect on desktops' } }
    'Enable Game Mode' = { if ($HW.Threads -le 6 -or $HW.RamGB -le 8) { Gn 2 5 'limited CPU/RAM gains from prioritizing' } else { Gn 0 2 'mostly helps 1% lows' } }
    'Disable Game Bar & Game DVR' = { if (-not $HW.Dvr) { Gn 0 1 'Game DVR is already off' } elseif ($HW.GpuScore -le 4) { Gn 3 8 'background capture costs a weaker GPU more' } else { Gn 2 5 'stops background capture' } }
    'Disable Fullscreen Optimizations' = { Gn 0 3 'exclusive fullscreen games only' }
    'Optimizations for Windowed Games' = { Gn 1 4 'borderless and windowed games' }
    'Hardware-Accelerated GPU Scheduling' = { if (-not $HW.HagsOk) { Gn 0 0 'GPU does not support HAGS' } elseif ($HW.Bound -eq 'CPU') { Gn 2 5 'CPU-bound, offloads scheduling to GPU' } else { Gn 0 2 'GPU-bound, small gain' } }
    'MMCSS Game Priority' = { Gn 0 2 'mainly smoother frametimes' }
    'CPU Priority Separation' = { if ($HW.Bound -eq 'CPU') { Gn 1 3 'CPU-bound, game gets longer time slices' } else { Gn 0 1 'GPU-bound, small gain' } }
    'Global Timer Resolution' = { Gn 0 1 'improves 1% lows more than average FPS' }
    'Disable HPET Platform Clock' = { Gn 0 3 'only helps if HPET was forced on' }
    'Disable Multiplane Overlay (MPO)' = { Gn 0 1 'fixes stutter, little FPS change' }
    'Disable VBS & Memory Integrity' = { if (-not $HW.Vbs) { Gn 0 0 'VBS is already off on this PC' } elseif ($HW.Bound -eq 'CPU') { Gn 5 15 'VBS is on and you are CPU-bound' } else { Gn 3 8 'VBS is on' } }
    'Disable NVIDIA Telemetry' = { if ($HW.GpuVendor -eq 'NVIDIA') { Gn 0 1 'less background CPU' } else { Gn 0 0 'no NVIDIA GPU detected' } }
    'Disable Telemetry' = { if ($HW.CpuScore -lt 5) { Gn 1 2 'frees a weaker CPU' } else { Gn 0 1 'less background CPU' } }
    'Disable Telemetry Tasks' = { Gn 0 1 'prevents random background spikes' }
    'Disable Copilot & Recall' = { if ($HW.RamGB -le 16) { Gn 0 2 'frees RAM' } else { Gn 0 1 'frees RAM' } }
    'Performance Visual Effects' = { if ($HW.IGpu) { Gn 2 5 'iGPU shares load with desktop effects' } else { Gn 0 2 'lighter desktop compositor work' } }
    'Disable Transparency' = { if ($HW.IGpu) { Gn 1 3 'iGPU skips blur work' } else { Gn 0 1 'small on a dedicated GPU' } }
    'Disable Background Apps' = { if ($HW.RamGB -le 8) { Gn 2 6 'only {0} GB RAM' $HW.RamGB } else { Gn 0 2 'fewer background processes' } }
    'Disable Memory Compression' = { if ($HW.RamGB -le 8) { Gn -4 0 'low RAM: compression helps, keep it on' } elseif ($HW.RamGB -ge 16) { Gn 0 2 'enough RAM, less CPU overhead' } else { Gn -1 1 'borderline RAM amount' } }
    'Disable SysMain (Superfetch)' = { if ($HW.Disk -eq 'HDD') { Gn -2 0 'HDD loads benefit from SysMain' } else { Gn 0 1 'less background disk work' } }
    'Disable Search Indexing' = { if ($HW.Disk -eq 'HDD') { Gn 1 3 'indexing keeps the HDD busy' } else { Gn 0 1 'less background I/O' } }
    'Disable Unneeded Services' = { Gn 0 1 'frees RAM' }
    'Disable Widgets' = { if ($HW.RamGB -le 8) { Gn 1 2 'frees RAM' } else { Gn 0 1 'frees RAM' } }
    'Disable Edge Background Running' = { if ($HW.RamGB -le 8) { Gn 1 2 'frees RAM' } else { Gn 0 1 'frees RAM' } }
    'Remove Bloatware Apps' = { if ($HW.RamGB -le 8) { Gn 1 3 'fewer background apps' } else { Gn 0 1 'fewer background apps' } }
}

foreach ($t in $Tweaks) {
    if ($Gain.ContainsKey($t.Name)) {
        $r = @(& $Gain[$t.Name])
        $t.GMin = [double]$r[0]; $t.GMax = [double]$r[1]; $t.GWhy = [string]$r[2]; $t.GArg = $r[3]
    }
}

function Get-TomlCut {
    param([string]$L)
    $q = [char]0
    for ($k = 0; $k -lt $L.Length; $k++) {
        $ch = $L[$k]
        if ($q -ne [char]0) {
            if ($ch -eq [char]'\' -and $q -eq [char]'"') { $k++ }
            elseif ($ch -eq $q) { $q = [char]0 }
        }
        elseif ($ch -eq [char]'"' -or $ch -eq [char]"'") { $q = $ch }
        elseif ($ch -eq [char]'#') { return $L.Substring(0, $k) }
    }
    $L
}

function Get-TomlDepth {
    param([string]$S)
    $q = [char]0; $d = 0
    for ($k = 0; $k -lt $S.Length; $k++) {
        $ch = $S[$k]
        if ($q -ne [char]0) {
            if ($ch -eq [char]'\' -and $q -eq [char]'"') { $k++ }
            elseif ($ch -eq $q) { $q = [char]0 }
        }
        elseif ($ch -eq [char]'"' -or $ch -eq [char]"'") { $q = $ch }
        elseif ($ch -eq [char]'[') { $d++ }
        elseif ($ch -eq [char]']') { $d-- }
    }
    $d
}

function Split-TomlList {
    param([string]$S)
    $out = [System.Collections.Generic.List[string]]::new()
    $q = [char]0; $d = 0; $st = 0
    for ($k = 0; $k -lt $S.Length; $k++) {
        $ch = $S[$k]
        if ($q -ne [char]0) {
            if ($ch -eq [char]'\' -and $q -eq [char]'"') { $k++ }
            elseif ($ch -eq $q) { $q = [char]0 }
        }
        elseif ($ch -eq [char]'"' -or $ch -eq [char]"'") { $q = $ch }
        elseif ($ch -eq [char]'[') { $d++ }
        elseif ($ch -eq [char]']') { $d-- }
        elseif ($ch -eq [char]',' -and $d -eq 0) { $out.Add($S.Substring($st, $k - $st)); $st = $k + 1 }
    }
    $out.Add($S.Substring($st))
    @($out | Where-Object { $_.Trim() })
}

function ConvertFrom-TomlValue {
    param([string]$R)
    $R = $R.Trim()
    if ($R -match '^"(.*)"$') { return [regex]::Unescape($Matches[1]) }
    if ($R -match "^'(.*)'$") { return $Matches[1] }
    if ($R -ceq 'true') { return $true }
    if ($R -ceq 'false') { return $false }
    if ($R -match '^[+-]?\d[\d_]*$') { return [int64]($R -replace '_', '') }
    if ($R -match '^[+-]?\d[\d_]*\.\d+$') { return [double]($R -replace '_', '') }
    if ($R.StartsWith('[') -and $R.EndsWith(']')) {
        $items = @(Split-TomlList $R.Substring(1, $R.Length - 2) | ForEach-Object { ConvertFrom-TomlValue $_ })
        return , $items
    }
    $script:TomlErr.Add((Tr 'Invalid value: {0}' $R))
    $null
}

function ConvertFrom-Toml {
    param([string]$Text)
    $root = [ordered]@{}
    $cur = $root
    $lines = $Text -split "`r?`n"
    $i = 0
    while ($i -lt $lines.Count) {
        $n = $i + 1
        $line = (Get-TomlCut $lines[$i]).Trim()
        $i++
        if (-not $line) { continue }
        if ($line -match '^\[\s*([A-Za-z0-9_.\-]+)\s*\]$') {
            $cur = $root
            foreach ($part in $Matches[1].ToLower().Split('.')) {
                if (-not $cur.Contains($part)) { $cur[$part] = [ordered]@{} }
                $cur = $cur[$part]
            }
            continue
        }
        if ($line -match '^("[^"]+"|[A-Za-z0-9_\-]+)\s*=\s*(.+)$') {
            $key = $Matches[1].Trim('"').ToLower()
            $raw = $Matches[2]
            while ((Get-TomlDepth $raw) -gt 0 -and $i -lt $lines.Count) {
                $raw += ' ' + (Get-TomlCut $lines[$i]).Trim()
                $i++
            }
            $cur[$key] = ConvertFrom-TomlValue $raw
            continue
        }
        $script:TomlErr.Add((Tr "Line {0}: cannot read '{1}'" $n $line))
    }
    $root
}

function Get-TomlBool {
    param($V, [string]$Where)
    if ($V -is [bool]) { return $V }
    $script:TplWarn.Add((Tr '{0} must be true or false' $Where))
    $null
}

function Import-DnsSection {
    param($D)
    $t = Find-Tweak 'set_dns_server'
    foreach ($k in @($D.Keys)) { if ($k -notin 'enabled', 'provider', 'primary', 'secondary', 'primary_v6', 'secondary_v6', 'doh', 'doh_template', 'ipv6') { $script:TplWarn.Add((Tr 'Unknown key {0}' "dns.$k")) } }
    if ($null -ne $D['enabled'] -and (Get-TomlBool $D['enabled'] 'dns.enabled') -eq $false) { $t.Sel = $false; $t.Opt = $null; return }
    $pv = if ($D['provider']) { ([string]$D['provider']).ToLower() } elseif ($D['primary']) { 'custom' } else { 'cloudflare' }
    $base = $Dns | Where-Object { $_.Id -eq $pv } | Select-Object -First 1
    if (-not $base) { $script:TplWarn.Add((Tr "Unknown DNS provider '{0}'" $pv)); return }
    $o = $base.Clone()
    if ($pv -eq 'custom') {
        $v4 = @(@($D['primary'], $D['secondary']) | Where-Object { $_ } | ForEach-Object { [string]$_ })
        $v6 = @(@($D['primary_v6'], $D['secondary_v6']) | Where-Object { $_ } | ForEach-Object { [string]$_ })
        $bad = @(@($v4 + $v6) | Where-Object { -not (Test-Ip $_) })
        if ($bad.Count) { $script:TplWarn.Add((Tr 'Invalid DNS address: {0}' ($bad -join ', '))); return }
        if (($v4.Count + $v6.Count) -eq 0) { $script:TplWarn.Add((Tr "dns.provider = 'custom' needs dns.primary")); return }
        $o.V4 = $v4; $o.V6 = $v6; $o.Name = 'Custom'; $o.Note = 'Your own servers'
        $o.Doh = if ($D['doh_template']) { [string]$D['doh_template'] } else { '' }
    }
    if ($null -ne $D['ipv6'] -and (Get-TomlBool $D['ipv6'] 'dns.ipv6') -eq $false) { $o.V6 = @() }
    if ($null -ne $D['doh'] -and (Get-TomlBool $D['doh'] 'dns.doh') -eq $false) { $o.Doh = '' }
    $t.Opt = $o
    $t.Sel = $true
}

function Import-Template {
    param([string]$Path)
    $script:TomlErr = [System.Collections.Generic.List[string]]::new()
    $script:TplWarn = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { $script:TplWarn.Add((Tr 'File not found: {0}' $Path)); return $false }
    $text = [IO.File]::ReadAllText($Path)
    $cfg = ConvertFrom-Toml $text
    $st0 = $cfg['settings']
    if ($st0 -and $st0['language'] -and -not $Cli.Lang) {
        $lg = ([string]$st0['language']).ToLower()
        if ($lg -in 'en', 'pl' -and $lg -ne $script:Lang) { $script:Lang = $lg; $script:TomlErr.Clear(); $cfg = ConvertFrom-Toml $text }
    }
    foreach ($e in $script:TomlErr) { $script:TplWarn.Add($e) }
    foreach ($k in @($cfg.Keys)) { if ($k -notin 'template', 'settings', 'categories', 'tweaks', 'dns') { $script:TplWarn.Add((Tr 'Unknown section [{0}]' $k)) } }
    $tp = $cfg['template']; $st = $cfg['settings']; $ct = $cfg['categories']; $tw = $cfg['tweaks']; $dn = $cfg['dns']
    if ($st -and $st['language']) {
        $lg = ([string]$st['language']).ToLower()
        if ($lg -notin 'en', 'pl') { $script:TplWarn.Add((Tr 'settings.language must be en or pl')) }
        elseif (-not $Cli.Lang) { $script:Lang = $lg }
    }
    $script:TplName = if ($tp -and $tp['name']) { [string]$tp['name'] } else { [IO.Path]::GetFileNameWithoutExtension($Path) }
    $script:TplAuthor = if ($tp -and $tp['author']) { [string]$tp['author'] } else { '' }
    foreach ($t in $Tweaks) { $t.Sel = $false; $t.Opt = $null }
    $preset = if ($st -and $st['preset']) { ([string]$st['preset']).ToLower() } else { 'none' }
    switch ($preset) {
        'none' { }
        'recommended' { foreach ($t in $Tweaks) { $t.Sel = $t.Rec } }
        'all' { foreach ($t in $Tweaks) { $t.Sel = $true } }
        'fps' { foreach ($t in $Tweaks) { $t.Sel = ($t.Fps -and $t.GMax -gt 0 -and $t.GMin -ge 0 -and $t.Tags -notmatch '-SECURITY') -or $t.Id -eq 'create_system_restore_point' } }
        'privacy' { foreach ($t in $Tweaks) { $t.Sel = ($t.Cat -eq 'Privacy') -or $t.Id -eq 'create_system_restore_point' } }
        default { $script:TplWarn.Add((Tr "Unknown preset '{0}' (use none, recommended, fps, privacy or all)" $preset)) }
    }
    if ($ct) {
        foreach ($k in @($ct.Keys)) {
            $cat = $Cats | Where-Object { $_ -eq $k } | Select-Object -First 1
            if (-not $cat) { $script:TplWarn.Add((Tr "Unknown category '{0}'" $k)); continue }
            $b = Get-TomlBool $ct[$k] "categories.$k"
            if ($null -ne $b) { foreach ($t in $Tweaks) { if ($t.Cat -eq $cat) { $t.Sel = $b } } }
        }
    }
    if ($tw) {
        foreach ($k in @($tw.Keys)) {
            if ($k -in 'enable', 'disable') {
                foreach ($id in @($tw[$k])) {
                    $t = Find-Tweak ([string]$id)
                    if ($t) { $t.Sel = ($k -eq 'enable') } else { $script:TplWarn.Add((Tr "Unknown tweak ID '{0}' in {1}" $id "tweaks.$k")) }
                }
            } else {
                $t = Find-Tweak $k
                if (-not $t) { $script:TplWarn.Add((Tr "Unknown tweak ID '{0}'" $k)); continue }
                $b = Get-TomlBool $tw[$k] "tweaks.$k"
                if ($null -ne $b) { $t.Sel = $b }
            }
        }
    }
    if ($dn) { Import-DnsSection $dn }
    if ($st) {
        foreach ($k in @($st.Keys)) { if ($k -notin 'preset', 'auto_apply', 'confirm', 'restart', 'base_fps', 'restore_point', 'language') { $script:TplWarn.Add((Tr 'Unknown key {0}' "settings.$k")) } }
        if ($null -ne $st['base_fps']) {
            $v = $st['base_fps']
            if ($v -is [int64] -and $v -gt 0) { $script:Base = [int]$v; $script:BaseSrc = 'user' } else { $script:TplWarn.Add((Tr 'settings.base_fps must be a whole number above 0')) }
        }
        if ($null -ne $st['auto_apply']) { $b = Get-TomlBool $st['auto_apply'] 'settings.auto_apply'; if ($null -ne $b) { $script:AutoApply = $b } }
        if ($null -ne $st['confirm']) { $b = Get-TomlBool $st['confirm'] 'settings.confirm'; if ($null -ne $b) { $script:SkipConfirm = -not $b } }
        if ($null -ne $st['restore_point']) { $b = Get-TomlBool $st['restore_point'] 'settings.restore_point'; if ($null -ne $b) { (Find-Tweak 'create_system_restore_point').Sel = $b } }
        if ($null -ne $st['restart']) {
            $r = ([string]$st['restart']).ToLower()
            if ($r -in 'ask', 'never', 'always') { $script:RestartMode = $r } else { $script:TplWarn.Add((Tr 'settings.restart must be ask, never or always')) }
        }
    }
    $true
}

function Export-Template {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { $docs = $HOME }
    $dir = Join-Path $docs 'CodeOpt\Templates'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir ('codeopt-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.toml')
    $q = [char]34
    $L = [System.Collections.Generic.List[string]]::new()
    $L.Add('[template]')
    $L.Add('name = "My CodeOpt template"')
    $L.Add("author = $q$env:USERNAME$q")
    $L.Add("created = $q$(Get-Date -Format 'yyyy-MM-dd')$q")
    $L.Add("description = $q$(@($Tweaks | Where-Object Sel).Count) tweaks exported from CodeOpt$q")
    $L.Add('')
    $L.Add('[settings]')
    $L.Add('preset = "none"')
    $L.Add('auto_apply = false')
    $L.Add('confirm = true')
    $L.Add("restart = $q$($script:RestartMode)$q")
    $L.Add("language = $q$($script:Lang)$q")
    if ($script:BaseSrc -eq 'user') { $L.Add("base_fps = $($script:Base)") }
    $L.Add('')
    $L.Add('[tweaks]')
    $L.Add('enable = [')
    foreach ($t in $Tweaks) { if ($t.Sel) { $L.Add("    $q$($t.Id)$q,") } }
    $L.Add(']')
    $d = Find-Tweak 'set_dns_server'
    if ($d.Sel) {
        $o = Get-DnsChoice $d
        $L.Add('')
        $L.Add('[dns]')
        $L.Add("provider = $q$($o.Id)$q")
        if ($o.Id -eq 'custom') {
            if ($o.V4.Count -gt 0) { $L.Add("primary = $q$($o.V4[0])$q") }
            if ($o.V4.Count -gt 1) { $L.Add("secondary = $q$($o.V4[1])$q") }
            if ($o.V6.Count -gt 0) { $L.Add("primary_v6 = $q$($o.V6[0])$q") }
            if ($o.V6.Count -gt 1) { $L.Add("secondary_v6 = $q$($o.V6[1])$q") }
            if ($o.Doh) { $L.Add("doh_template = $q$($o.Doh)$q") }
        } else {
            $L.Add('doh = ' + $(if ($o.Doh) { 'true' } else { 'false' }))
            $L.Add('ipv6 = ' + $(if ($o.V6.Count) { 'true' } else { 'false' }))
        }
    }
    [IO.File]::WriteAllText($path, ($L -join "`r`n") + "`r`n", [Text.UTF8Encoding]::new($false))
    $path
}

function Get-DnsLatency {
    $jobs = @{}
    foreach ($d in $Dns) {
        if ($d.V4.Count) { $jobs[$d.Id] = ([System.Net.NetworkInformation.Ping]::new()).SendPingAsync($d.V4[0], 1000) }
    }
    try { [void][System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]@($jobs.Values), 2500) } catch { }
    $r = @{}
    foreach ($k in $jobs.Keys) {
        $j = $jobs[$k]
        $r[$k] = if ([string]$j.Status -eq 'RanToCompletion' -and [string]$j.Result.Status -eq 'Success') { [int]$j.Result.RoundtripTime } else { -1 }
    }
    $r
}

function Get-BestDns {
    $b = $null; $m = [int]::MaxValue
    foreach ($k in $script:DnsPing.Keys) { $v = $script:DnsPing[$k]; if ($v -ge 0 -and $v -lt $m) { $m = $v; $b = $k } }
    $b
}

function Read-CustomDns {
    Clear-Host
    Show-Banner
    Out-Line @((S ''))
    Out-Line @((S (Tr '  CUSTOM DNS ') 'White' 'DarkBlue'), (S (Tr '   IPv4 or IPv6, leave secondary empty to use one server') 'DarkCyan'))
    Out-Line @((S ''))
    [Console]::CursorVisible = $true
    Write-Host (Tr '  Primary   : ') -ForegroundColor Cyan -NoNewline
    $a1 = ([string](Read-Host)).Trim()
    Write-Host (Tr '  Secondary : ') -ForegroundColor Cyan -NoNewline
    $a2 = ([string](Read-Host)).Trim()
    [Console]::CursorVisible = $false
    $all = @(@($a1, $a2) | Where-Object { $_ })
    $bad = @($all | Where-Object { -not (Test-Ip $_) })
    if ($all.Count -eq 0 -or $bad.Count) {
        Write-Host (Tr '  Invalid address. Press any key...') -ForegroundColor Red
        [void][Console]::ReadKey($true)
        Clear-Host
        return $null
    }
    @{ Id = 'custom'; Name = 'Custom'; V4 = @($all | Where-Object { $_ -notmatch ':' }); V6 = @($all | Where-Object { $_ -match ':' }); Doh = ''; Note = 'Your own servers' }
}

function Show-DnsPicker {
    param($t)
    $list = @($Dns)
    $ix = 0
    $curId = if ($t.Sel) { (Get-DnsChoice $t).Id } else { '' }
    for ($k = 0; $k -lt $list.Count; $k++) { if ($list[$k].Id -eq $curId) { $ix = $k } }
    $top = 0
    if (-not $script:DnsPing) {
        Clear-Host
        Show-Banner
        Out-Line @((S ''))
        Out-Line @((S (Tr '  Measuring ping to DNS providers...') 'Cyan'))
        $script:DnsPing = Get-DnsLatency
    }
    $best = Get-BestDns
    Clear-Host
    while ($true) {
        $rows = [Math]::Max(4, [Console]::WindowHeight - 16)
        if ($ix -lt $top) { $top = $ix }
        if ($ix -ge $top + $rows) { $top = $ix - $rows + 1 }
        [Console]::SetCursorPosition(0, 0)
        Show-Banner
        Out-Line @((S ''))
        Out-Line @((S (Tr '  SELECT DNS PROVIDER ') 'White' 'DarkBlue'), (S (Tr '   ping is measured from this PC') 'DarkCyan'))
        Out-Line @((S ('      ' + (Tr 'PROVIDER').PadRight(23) + (Tr 'PRIMARY').PadRight(17) + (Tr 'SECONDARY').PadRight(17) + 'PING'.PadRight(9) + (Tr 'NOTES')) 'DarkCyan'))
        Show-Rule
        for ($r = 0; $r -lt $rows; $r++) {
            $j = $top + $r
            if ($j -ge $list.Count) { Out-Line @((S '')); continue }
            $d = $list[$j]
            $src = if ($d.Id -eq 'custom' -and $t.Opt -and $t.Opt.Id -eq 'custom') { $t.Opt } else { $d }
            $p1 = if ($src.V4.Count) { $src.V4[0] } elseif ($src.V6.Count) { $src.V6[0] } else { '-' }
            $p2 = if ($src.V4.Count -gt 1) { $src.V4[1] } else { '-' }
            $ms = $script:DnsPing[$d.Id]
            $pt = if ($null -eq $ms) { '' } elseif ($ms -lt 0) { Tr 'timeout' } else { "$ms ms" }
            $pc = if ($null -eq $ms -or $ms -lt 0) { 'DarkGray' } elseif ($ms -le 20) { 'Cyan' } elseif ($ms -le 50) { 'White' } else { 'DarkYellow' }
            $note = if ($d.Id -eq $best) { (Tr 'FASTEST') + ' ' + $G.Dot + ' ' + (Tr $d.Note) } else { Tr $d.Note }
            $nc = if ($d.Id -eq $best) { 'Cyan' } else { 'Gray' }
            $mark = if ($d.Id -eq $curId) { '[' + $G.On + ']' } else { '[ ]' }
            if ($j -eq $ix) {
                Out-Line @((S ('  ' + $G.Ptr + ' ') 'Cyan'), (S ($mark + ' ' + (Tr $d.Name).PadRight(23)) 'White' 'DarkBlue'), (S $p1.PadRight(17) 'White' 'DarkBlue'), (S $p2.PadRight(17) 'White' 'DarkBlue'), (S $pt.PadRight(9) $pc 'DarkBlue'), (S $note $nc))
            } else {
                $mc = if ($d.Id -eq $curId) { 'Cyan' } else { 'DarkGray' }
                Out-Line @((S '    '), (S $mark $mc), (S (' ' + (Tr $d.Name).PadRight(23)) 'Gray'), (S $p1.PadRight(17) 'DarkCyan'), (S $p2.PadRight(17) 'DarkCyan'), (S $pt.PadRight(9) $pc), (S $note $nc))
            }
        }
        Show-Rule
        $d = $list[$ix]
        $v6 = if ($d.V6.Count) { $d.V6 -join ', ' } else { Tr 'none' }
        $doh = if ($d.Doh) { $d.Doh } else { Tr 'not available' }
        Out-Line @((S (Tr '  IPv6 ') 'DarkCyan'), (S $v6 'Gray'), (S (Tr '   DoH ') 'DarkCyan'), (S $doh 'Gray'))
        Out-Line @((S "  $($G.Up)$($G.Dn) " 'Cyan'), (S (Tr 'move  ') 'DarkGray'), (S (Tr 'Enter/Space ') 'Cyan'), (S (Tr 'select  ') 'DarkGray'), (S (Tr 'B ') 'Cyan'), (S (Tr 'pick fastest  ') 'DarkGray'), (S (Tr 'T ') 'Cyan'), (S (Tr 'test ping again  ') 'DarkGray'), (S (Tr 'Del ') 'Cyan'), (S (Tr 'unselect  ') 'DarkGray'), (S (Tr 'Esc ') 'Cyan'), (S (Tr 'back') 'DarkGray'))
        $key = [string][Console]::ReadKey($true).Key
        switch ($key) {
            'UpArrow' { $ix = ($ix - 1 + $list.Count) % $list.Count }
            'DownArrow' { $ix = ($ix + 1) % $list.Count }
            'Home' { $ix = 0 }
            'End' { $ix = $list.Count - 1 }
            'T' {
                Out-Line @((S (Tr '  Measuring ping to DNS providers...') 'Cyan'))
                $script:DnsPing = Get-DnsLatency
                $best = Get-BestDns
                Clear-Host
            }
            'B' {
                $bd = $list | Where-Object { $_.Id -eq $best } | Select-Object -First 1
                if ($bd) { $t.Opt = $bd.Clone(); $t.Sel = $true; return }
            }
            'Delete' { $t.Sel = $false; $t.Opt = $null; return }
            'Backspace' { $t.Sel = $false; $t.Opt = $null; return }
            'Escape' { return }
            default {
                if ($key -in 'Enter', 'Spacebar') {
                    if ($d.Id -eq 'custom') {
                        $o = Read-CustomDns
                        if ($o) { $t.Opt = $o; $t.Sel = $true; return }
                    } else {
                        $t.Opt = $d.Clone(); $t.Sel = $true; return
                    }
                }
            }
        }
    }
}

function Get-FpsText {
    param([double]$Lo, [double]$Hi)
    $a = [int][math]::Round($script:Base * $Lo / 100)
    $b = [int][math]::Round($script:Base * $Hi / 100)
    if ($a -eq 0 -and $b -eq 0) { return '' }
    if ($a -eq $b) { return ('{0:+0;-0} FPS' -f $a) }
    if ($a -lt 0) { return ('{0} to {1:+0;-0;0} FPS' -f $a, $b) }
    '+{0}-{1} FPS' -f $a, $b
}

function Get-Total {
    $lo = 1.0; $hi = 1.0
    foreach ($t in $Tweaks) { if ($t.Sel) { $lo *= (1 + $t.GMin / 100); $hi *= (1 + $t.GMax / 100) } }
    @((($lo - 1) * 80), (($hi - 1) * 80))
}

function S { param($t, $f = 'Gray', $b = $null) @{ t = [string]$t; f = $f; b = $b } }

function Out-Line {
    param([object[]]$Seg)
    $left = $script:W
    foreach ($s in $Seg) {
        if ($left -le 0) { break }
        $t = $s.t
        if ($t.Length -gt $left) { $t = $t.Substring(0, $left) }
        $b = if ($s.b) { $s.b } else { $script:Bg }
        Write-Host $t -ForegroundColor $s.f -BackgroundColor $b -NoNewline
        $left -= $t.Length
    }
    if ($left -gt 0) { Write-Host (' ' * $left) -BackgroundColor $script:Bg -NoNewline }
    Write-Host ''
}

function Show-Banner {
    $in = 82
    $title = ' C O D E O P T '
    $sub = (Tr 'Windows Tweaks & Optimizer') + ' ' + $G.Dot + ' v2.1 ' + $G.Dot + ' ' + $script:Lang.ToUpper()
    $gap = $in - $title.Length - $sub.Length - 2
    Out-Line @((S ('  ' + $G.TL + ($G.H * $in) + $G.TR) 'Blue'))
    Out-Line @((S ('  ' + $G.V + ' ') 'Blue'), (S $title 'White' 'DarkBlue'), (S (' ' * $gap)), (S $sub 'Cyan'), (S ' '), (S $G.V 'Blue'))
    Out-Line @((S ('  ' + $G.BL + ($G.H * $in) + $G.BR) 'Blue'))
    $dev = if ($HW.Laptop) { Tr 'Laptop' } else { Tr 'Desktop' }
    $hz = if ($HW.Hz -gt 0) { "$($HW.Hz) Hz" } else { '?' }
    $mhz = if ($HW.RamMHz -gt 0) { " $($HW.RamMHz) MHz" } else { '' }
    $vbs = if ($HW.Vbs) { Tr 'On' } else { Tr 'Off' }
    $bl = if ($script:BaseSrc -eq 'est') { Tr '~{0} FPS est.' $script:Base } else { Tr '{0} FPS (yours)' $script:Base }
    Out-Line @((S (Tr '   CPU ') 'DarkCyan'), (S "$($HW.Cpu) $($HW.Cores)C/$($HW.Threads)T" 'White'), (S (Tr '   GPU ') 'DarkCyan'), (S "$($HW.Gpu) $($HW.Vram) GB" 'White'))
    Out-Line @((S (Tr '   RAM ') 'DarkCyan'), (S "$($HW.RamGB) GB$mhz x$($HW.Sticks)" 'White'), (S (Tr '   DISK ') 'DarkCyan'), (S $HW.Disk 'White'), (S (Tr '   DISPLAY ') 'DarkCyan'), (S $hz 'White'), (S (Tr '   DEVICE ') 'DarkCyan'), (S $dev 'White'), (S (Tr '   VBS ') 'DarkCyan'), (S $vbs 'White'))
    Out-Line @((S (Tr '   OS ') 'DarkCyan'), (S $os 'White'), (S (Tr '   BOTTLENECK ') 'DarkCyan'), (S $HW.Bound 'Cyan'), (S (Tr '   BASE ') 'DarkCyan'), (S $bl 'Cyan'))
    if ($script:TplName) {
        $by = if ($script:TplAuthor) { Tr ' by {0}' $script:TplAuthor } else { '' }
        $wn = if ($script:TplWarn.Count) { Tr '   {0} warning(s)' $script:TplWarn.Count } else { '' }
        Out-Line @((S (Tr '   TEMPLATE ') 'DarkCyan'), (S $script:TplName 'White'), (S $by 'DarkCyan'), (S $wn 'DarkYellow'))
    }
}

function Show-Rule { Out-Line @((S ('  ' + ($G.L * 84)) 'DarkBlue')) }

function Draw {
    param($Items, $Rows)
    [Console]::SetCursorPosition(0, 0)
    Show-Banner
    Out-Line @((S ''))
    $seg = [System.Collections.Generic.List[object]]::new()
    $seg.Add((S '  '))
    for ($k = 0; $k -lt $Cats.Count; $k++) {
        $cnt = @($Tweaks | Where-Object { $_.Cat -eq $Cats[$k] -and $_.Sel }).Count
        $label = if ($cnt -gt 0) { " $(Tr $Cats[$k]) $cnt " } else { " $(Tr $Cats[$k]) " }
        if ($k -eq $script:c) { $seg.Add((S $label 'White' 'DarkBlue')) }
        elseif ($cnt -gt 0) { $seg.Add((S $label 'Cyan')) }
        else { $seg.Add((S $label 'DarkCyan')) }
        $seg.Add((S ' '))
    }
    Out-Line $seg
    Show-Rule
    $more = $script:top -gt 0
    Out-Line @((S $(if ($more) { "    $($G.Tri) " + (Tr 'more') } else { '' }) 'DarkBlue'))
    for ($r = 0; $r -lt $Rows; $r++) {
        $j = $script:top + $r
        if ($j -lt $Items.Count) {
            $t = $Items[$j]
            $cur = ($j -eq $script:i)
            $box = if ($t.Sel) { '[' + $G.On + ']' } else { '[ ]' }
            $bf = if ($t.Sel) { 'Cyan' } else { 'DarkGray' }
            $rec = if ($t.Rec) { ' ' + (Tr 'REC') } else { '' }
            $tf = if ($t.Fps) { 'Cyan' } elseif ($t.Tags -match 'SECURITY|SAFE') { 'Blue' } else { 'DarkCyan' }
            $est = Get-FpsText $t.GMin $t.GMax
            $ef = if ($t.GMin -lt 0) { 'DarkYellow' } else { 'Cyan' }
            if ($cur) {
                Out-Line @((S ('  ' + $G.Ptr + ' ') 'Cyan'), (S $box $bf 'DarkBlue'), (S (' ' + (Get-TweakName $t).PadRight($script:NameW)) 'White' 'DarkBlue'), (S ' '), (S (Get-TagText $t.Tags).PadRight($script:TagW) $tf), (S $est.PadRight(14) $ef), (S $rec 'DarkCyan'))
            } else {
                $nf = if ($t.Sel) { 'White' } else { 'Gray' }
                Out-Line @((S '    '), (S $box $bf), (S (' ' + (Get-TweakName $t).PadRight($script:NameW)) $nf), (S ' '), (S (Get-TagText $t.Tags).PadRight($script:TagW) $tf), (S $est.PadRight(14) $ef), (S $rec 'DarkBlue'))
            }
        } else {
            Out-Line @((S ''))
        }
    }
    $less = ($script:top + $Rows) -lt $Items.Count
    Out-Line @((S $(if ($less) { "    $($G.TriD) " + (Tr 'more') } else { '' }) 'DarkBlue'))
    Show-Rule
    $cur = if ($Items.Count) { $Items[$script:i] } else { $null }
    $desc = if ($cur) { Get-TweakDesc $cur } else { '' }
    if ($cur -and $cur.Pick -and $cur.Sel) {
        $o = Get-DnsChoice $cur
        $ips = @(@($o.V4) + @($o.V6) | Select-Object -First 2)
        $ipt = if ($ips.Count) { ' (' + ($ips -join ', ') + ')' } else { '' }
        $desc = Tr 'Using {0}{1}. {2}. Press Space to change.' (Tr $o.Name) $ipt (Tr $o.Note)
    }
    $dt = if ($cur -and $cur.Tags) { '[' + (Get-TagText $cur.Tags) + '] ' } else { '' }
    $df = if ($cur -and $cur.Fps) { 'Cyan' } else { 'DarkCyan' }
    Out-Line @((S ('  ' + [string][char]0x00BB + ' ') 'Cyan'), (S $dt $df), (S $desc 'Gray'))
    if ($cur -and ($cur.GMin -ne 0 -or $cur.GMax -ne 0)) {
        $ec = if ($cur.GMin -lt 0) { 'DarkYellow' } else { 'Cyan' }
        Out-Line @((S (Tr '    Est. ') 'DarkCyan'), (S (Get-FpsText $cur.GMin $cur.GMax) $ec), (S (Tr '  ({0:+0;-0;0}% to {1:+0;-0;0}%)  ' $cur.GMin $cur.GMax) 'DarkCyan'), (S (Tr $cur.GWhy $cur.GArg) 'Gray'))
    } elseif ($cur -and $cur.GWhy) {
        Out-Line @((S (Tr '    Est. ') 'DarkCyan'), (S (Tr 'no FPS change  ') 'DarkGray'), (S (Tr $cur.GWhy $cur.GArg) 'Gray'))
    } else {
        Out-Line @((S (Tr '    Est. ') 'DarkCyan'), (S (Tr 'no direct FPS impact') 'DarkGray'))
    }
    $rbt = if ($cur) { $cur.Reboot } else { 'None' }
    $rt, $rc = switch ($rbt) { 'Restart' { (Tr 'Restart required'), 'DarkYellow' } 'Sign out' { (Tr 'Sign out required'), 'Yellow' } default { (Tr 'No restart needed'), 'Cyan' } }
    $nr = @($Tweaks | Where-Object { $_.Sel -and $_.Reboot -eq 'Restart' }).Count
    $ns = @($Tweaks | Where-Object { $_.Sel -and $_.Reboot -eq 'Sign out' }).Count
    $idt = if ($cur) { $cur.Id } else { '' }
    Out-Line @((S (Tr '    Apply ') 'DarkCyan'), (S $rt.PadRight(22) $rc), (S (Tr 'ID ') 'DarkCyan'), (S $idt.PadRight(38) 'DarkGray'), (S (Tr 'Selection needs ') 'DarkCyan'), (S (Tr '{0} restart, {1} sign out' $nr $ns) 'Gray'))
    $sel = @($Tweaks | Where-Object Sel).Count
    $tt = Get-Total
    $tg = Get-FpsText $tt[0] $tt[1]
    if (-not $tg) { $tg = '+0 FPS' }
    $tp = Tr '  ({0:+0;-0;0}% to {1:+0;-0;0}%)' $tt[0] $tt[1]
    Out-Line @((S (Tr '  Selected ') 'DarkCyan'), (S "$sel" 'White'), (S (Tr ' of {0}' $Tweaks.Count) 'DarkCyan'), (S (Tr '   Est. total gain ') 'DarkCyan'), (S $tg 'Cyan'), (S $tp 'DarkCyan'), (S (Tr '   Category {0}/{1}' ($script:c + 1) $Cats.Count) 'DarkCyan'))
    Out-Line @((S "  $($G.Up)$($G.Dn) " 'Cyan'), (S (Tr 'move  ') 'DarkGray'), (S "$($G.Lf)$($G.Rt) " 'Cyan'), (S (Tr 'category  ') 'DarkGray'), (S (Tr 'Space ') 'Cyan'), (S (Tr 'toggle / pick  ') 'DarkGray'), (S (Tr 'A ') 'Cyan'), (S (Tr 'all in tab  ') 'DarkGray'), (S (Tr 'R ') 'Cyan'), (S (Tr 'recommended  ') 'DarkGray'), (S (Tr 'C ') 'Cyan'), (S (Tr 'clear') 'DarkGray'))
    Out-Line @((S (Tr '  F ') 'Cyan'), (S (Tr 'my FPS  ') 'DarkGray'), (S (Tr 'E ') 'Cyan'), (S (Tr 'export template  ') 'DarkGray'), (S (Tr 'L ') 'Cyan'), (S (Tr 'language PL/EN  ') 'DarkGray'), (S (Tr 'Enter ') 'Cyan'), (S (Tr 'apply  ') 'DarkGray'), (S (Tr 'Esc ') 'Cyan'), (S (Tr 'exit') 'DarkGray'))
}

function Invoke-Apply {
    $list = @($Tweaks | Where-Object Sel)
    if ($list.Count -eq 0) {
        if ($script:AutoApply) { Write-Host (Tr '  The template selects no tweaks. Nothing to apply.') -ForegroundColor DarkYellow }
        return
    }
    Clear-Host
    Show-Banner
    Out-Line @((S ''))
    Out-Line @((S (Tr '  Ready to apply ') 'Gray'), (S "$($list.Count)" 'White'), (S (Tr ' tweaks.  ') 'Gray'), (S (Tr 'Enter ') 'Cyan'), (S (Tr 'confirm   ') 'DarkGray'), (S (Tr 'Esc ') 'Cyan'), (S (Tr 'cancel') 'DarkGray'))
    $tt = Get-Total
    $tg = Get-FpsText $tt[0] $tt[1]
    if (-not $tg) { $tg = '+0 FPS' }
    Out-Line @((S (Tr '  Estimated gain ') 'DarkCyan'), (S $tg 'Cyan'), (S (Tr '  ({0:+0;-0;0}% to {1:+0;-0;0}%) from a base of {2} FPS' $tt[0] $tt[1] $script:Base) 'DarkCyan'))
    $nr = @($list | Where-Object Reboot -eq 'Restart').Count
    $ns = @($list | Where-Object Reboot -eq 'Sign out').Count
    Out-Line @((S (Tr '  Needs ') 'DarkCyan'), (S (Tr '{0} restart' $nr) 'DarkYellow'), (S ', ' 'DarkCyan'), (S (Tr '{0} sign out' $ns) 'Yellow'), (S ', ' 'DarkCyan'), (S (Tr '{0} instant' ($list.Count - $nr - $ns)) 'Cyan'))
    if (-not $script:SkipConfirm) {
        while ($true) {
            $k = [Console]::ReadKey($true).Key
            if ($k -eq 'Escape') { Clear-Host; return }
            if ($k -eq 'Enter') { break }
        }
    }
    Out-Line @((S ''))
    $n = $list.Count; $k = 0; $ok = 0
    foreach ($t in $list) {
        $k++
        Write-Host ('  ' + ("[$k/$n]").PadRight(8)) -ForegroundColor DarkCyan -NoNewline
        Write-Host (Get-TweakName $t).PadRight($script:NameW + 2) -ForegroundColor White -NoNewline
        Write-Host (Get-TagText $t.Tags).PadRight($script:TagW + 1) -ForegroundColor $(if ($t.Fps) { 'Cyan' } else { 'DarkCyan' }) -NoNewline
        try {
            & $t.Do $t *> $null
            Write-Host (" $($G.Ok) " + (Tr 'done')) -ForegroundColor Cyan -NoNewline
            Write-Host $(switch ($t.Reboot) { 'Restart' { Tr '  restart' } 'Sign out' { Tr '  sign out' } default { '' } }) -ForegroundColor DarkYellow
            $ok++
        } catch {
            Write-Host (Tr ' x failed') -ForegroundColor Red
        }
        $t.Sel = $false
    }
    $barW = 50
    $fill = [int][math]::Round($barW * $ok / $n)
    Write-Host ''
    Write-Host '  ' -NoNewline
    Write-Host ($G.Full * $fill) -ForegroundColor Blue -NoNewline
    Write-Host ($G.Shade * ($barW - $fill)) -ForegroundColor DarkBlue -NoNewline
    Write-Host "  $ok/$n" -ForegroundColor White
    Write-Host ''
    $nr = @($list | Where-Object Reboot -eq 'Restart').Count
    $ns = @($list | Where-Object Reboot -eq 'Sign out').Count
    Write-Host (Tr '  Estimated gain: ') -ForegroundColor DarkCyan -NoNewline
    Write-Host $tg -ForegroundColor Cyan -NoNewline
    Write-Host (Tr '  (real results depend on the game, settings and drivers)') -ForegroundColor DarkGray
    $need = ''
    if ($nr) { Write-Host (Tr '  {0} tweak(s) need a restart to take effect.' $nr) -ForegroundColor DarkYellow; $need = 'Restart' }
    elseif ($ns) { Write-Host (Tr '  {0} tweak(s) need you to sign out and back in.' $ns) -ForegroundColor Yellow; $need = 'Sign out' }
    else { Write-Host (Tr '  All changes are active now. No restart needed.') -ForegroundColor Cyan }
    if ($need) {
        $go = $false
        if ($script:RestartMode -eq 'always') { $go = $true }
        elseif ($script:RestartMode -eq 'ask') {
            Write-Host (Tr $(if ($need -eq 'Restart') { '  Restart now? ' } else { '  Sign out now? ' })) -ForegroundColor Cyan -NoNewline
            Write-Host (Tr '[Y] yes  [N] later') -ForegroundColor DarkGray
            while ($true) {
                $kk = [string][Console]::ReadKey($true).Key
                if ($kk -in 'Y', 'T') { $go = $true; break }
                if ($kk -in 'N', 'Escape', 'Enter') { break }
            }
        }
        if ($go) {
            [Console]::CursorVisible = $true
            if ($need -eq 'Restart') {
                Write-Host (Tr '  Restarting in 5 seconds...') -ForegroundColor Cyan
                shutdown.exe /r /t 5 /c 'CodeOpt is restarting your PC to apply tweaks.' | Out-Null
            } else {
                Write-Host (Tr '  Signing out...') -ForegroundColor Cyan
                Start-Sleep -Seconds 2
                shutdown.exe /l | Out-Null
            }
            exit
        }
    }
    if ($script:AutoApply) { return }
    Write-Host (Tr '  Press any key to return to the menu...') -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
    Clear-Host
}

$script:TplName = ''; $script:TplAuthor = ''; $script:TplWarn = [System.Collections.Generic.List[string]]::new()
$script:TomlErr = [System.Collections.Generic.List[string]]::new()
$script:RestartMode = 'ask'; $script:AutoApply = $false; $script:SkipConfirm = $false; $script:DnsPing = $null

$Host.UI.RawUI.WindowTitle = 'CodeOpt Optimizer'
Update-Layout
$Host.UI.RawUI.BackgroundColor = 'Black'
[Console]::CursorVisible = $false
Clear-Host

if ($Cli.Template) {
    $ok = Import-Template $Cli.Template
    if (-not $ok) { $script:TplName = '' }
    if ($Cli.Apply) { $script:AutoApply = $true }
    if ($Cli.Yes) { $script:SkipConfirm = $true }
    if (-not $ok) { $script:AutoApply = $false }
    if ($script:TplWarn.Count) {
        Show-Banner
        Out-Line @((S ''))
        Out-Line @((S (Tr '  TEMPLATE WARNINGS ') 'White' 'DarkBlue'), (S "   $($Cli.Template)" 'DarkCyan'))
        foreach ($w in $script:TplWarn) { Out-Line @((S "  $($G.Dot) " 'DarkYellow'), (S $w 'Gray')) }
        Out-Line @((S ''))
        if (-not $ok) { Out-Line @((S (Tr '  The template could not be loaded. Press any key to open the menu...') 'DarkGray')) }
        elseif (-not $script:SkipConfirm) { Out-Line @((S (Tr '  Press any key to continue, Esc to quit...') 'DarkGray')) }
        if (-not $ok -or -not $script:SkipConfirm) {
            if ([Console]::ReadKey($true).Key -eq 'Escape') { [Console]::CursorVisible = $true; [Console]::ResetColor(); exit }
        }
        Clear-Host
    }
}

if ($script:AutoApply) {
    Invoke-Apply
    if (-not $script:SkipConfirm) {
        Write-Host (Tr '  Press any key to exit...') -ForegroundColor DarkGray
        [void][Console]::ReadKey($true)
    }
    [Console]::CursorVisible = $true
    [Console]::ResetColor()
    exit
}

$script:c = 0; $script:i = 0; $script:top = 0
$lastW = 0; $lastH = 0
$run = $true

while ($run) {
    if ([Console]::WindowWidth -ne $lastW -or [Console]::WindowHeight -ne $lastH) {
        $lastW = [Console]::WindowWidth; $lastH = [Console]::WindowHeight
        $script:W = [Math]::Max(40, $lastW - 1)
        Clear-Host
    }
    $items = @($Tweaks | Where-Object { $_.Cat -eq $Cats[$script:c] })
    $rows = [Math]::Max(4, [Console]::WindowHeight - 21)
    if ($script:i -ge $items.Count) { $script:i = [Math]::Max(0, $items.Count - 1) }
    if ($script:i -lt $script:top) { $script:top = $script:i }
    if ($script:i -ge $script:top + $rows) { $script:top = $script:i - $rows + 1 }
    Draw $items $rows
    $key = [Console]::ReadKey($true)
    switch ($key.Key) {
        'UpArrow' { $script:i = ($script:i - 1 + $items.Count) % $items.Count }
        'DownArrow' { $script:i = ($script:i + 1) % $items.Count }
        'LeftArrow' { $script:c = ($script:c - 1 + $Cats.Count) % $Cats.Count; $script:i = 0; $script:top = 0 }
        'RightArrow' { $script:c = ($script:c + 1) % $Cats.Count; $script:i = 0; $script:top = 0 }
        'Tab' { $script:c = ($script:c + 1) % $Cats.Count; $script:i = 0; $script:top = 0 }
        'Home' { $script:i = 0 }
        'End' { $script:i = $items.Count - 1 }
        'Spacebar' {
            $t = $items[$script:i]
            if ($t.Pick) { Show-DnsPicker $t; $lastW = 0 } else { $t.Sel = -not $t.Sel }
        }
        'E' {
            $p = Export-Template
            Clear-Host
            Show-Banner
            Out-Line @((S ''))
            Out-Line @((S (Tr '  Template saved  ') 'Cyan'), (S $p 'White'))
            Out-Line @((S (Tr '  Load it with    ') 'DarkCyan'), (S ".\CodeOpt.ps1 --template `"$p`"" 'Gray'))
            Out-Line @((S ''))
            Out-Line @((S (Tr '  Press any key...') 'DarkGray'))
            [void][Console]::ReadKey($true)
            $lastW = 0
        }
        'A' {
            $all = @($items | Where-Object { -not $_.Sel }).Count -eq 0
            foreach ($t in $items) { $t.Sel = -not $all }
        }
        'R' { foreach ($t in $Tweaks) { $t.Sel = $t.Rec } }
        'C' { foreach ($t in $Tweaks) { $t.Sel = $false } }
        'F' {
            [Console]::CursorVisible = $true
            Clear-Host
            Show-Banner
            Out-Line @((S ''))
            Out-Line @((S (Tr '  Type the FPS you get now in your game for exact numbers. Leave empty for the hardware estimate.') 'Gray'))
            Write-Host (Tr '  Your FPS: ') -ForegroundColor Cyan -NoNewline
            $v = Read-Host
            if ($v -match '^\d+$' -and [int]$v -gt 0) { $script:Base = [int]$v; $script:BaseSrc = 'user' }
            else { $script:Base = $HW.BaseFps; $script:BaseSrc = 'est' }
            [Console]::CursorVisible = $false
            $lastW = 0
        }
        'L' {
            $script:Lang = if ($script:Lang -eq 'pl') { 'en' } else { 'pl' }
            Set-Reg 'HKCU:\Software\CodeOpt' 'Language' $script:Lang 'String'
            Update-Layout
            $lastW = 0
        }
        'Enter' { Invoke-Apply; $lastW = 0 }
        'Escape' { $run = $false }
        'Q' { $run = $false }
    }
}

[Console]::CursorVisible = $true
[Console]::ResetColor()
Clear-Host
Write-Host ''
Write-Host (Tr '  CodeOpt closed. Restart to apply all changes.') -ForegroundColor Cyan
Write-Host ''
