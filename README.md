![codeopt](https://github.com/Zeis01/codeopt/blob/main/images/icon.png)

# codeopt
**codeopt** is powershell optimizer in CLI version

# How to use?

- Open Powershell (app requires admin rights, The application automatically restarts with administrator privileges.)

- Copy and enter this command to console
```powershell
irm https://raw.githubusercontent.com/Zeis01/codeopt/refs/heads/main/codeopt.ps1 | iex
```

- Or download file and run
```powershell
.\codeopt.ps1
```

# codeopt Templates (TOML)

A **template** is a small `.toml` text file that tells codeopt which tweaks to select, which DNS server to use and how to behave after applying. Templates let you:

- keep your favourite setup and re-apply it after a Windows reinstall or a big update
- share a configuration with friends or a team
- run codeopt unattended, for example on several PCs

---

## 1. Quick start

```powershell
.\codeopt.ps1 --template competitive-fps.toml
```

codeopt opens with the template's tweaks already selected and shows the template name in the header. Review the selection, change anything you like, then press **Enter** to apply.

To apply without opening the menu:

```powershell
.\codeopt.ps1 --template competitive-fps.toml --apply --yes
```

You don't need to start PowerShell as Administrator. codeopt asks for elevation through UAC by itself and passes your template and options to the elevated window. Relative paths are resolved first, so `--template .\my.toml` still works after elevation.

> **Tip:** The quickest way to make a template is to select tweaks in the menu and press **E**. codeopt saves your current selection, including the DNS choice and your FPS number, to `Documents\codeopt\Templates\codeopt-<date>.toml`.

---

## 2. Command-line options

| Option | Description |
|---|---|
| `--template <file.toml>` | Load a template. Also accepted: `--template=<file>`, `-t <file>`, or just the file path as the only argument |
| `--lang <en\|pl>` | Interface language: `en` (English) or `pl` (Polish). Also accepted: `--lang=pl` |
| `--apply` | Apply the template right away instead of opening the menu. Needs `--template` |
| `--yes` | Skip the confirmation screen and every "press any key" pause. Use it with `--apply` for unattended runs |
| `--list` | Print every tweak ID with its category, restart requirement and whether it's recommended. Doesn't need admin rights |
| `--help` | Show the help text |

`--apply`, `--yes` and `--lang` override `auto_apply`, `confirm` and `language` in the file.

---

## 3. File layout

A template has up to five sections. **All sections and keys are optional**, so an empty file is a valid template that selects nothing.

```toml
[template]      # name and author shown in the header
[settings]      # preset, restart behaviour, auto apply, FPS baseline
[categories]    # switch whole tabs on or off
[tweaks]        # pick individual tweaks by ID
[dns]           # which DNS server "Set DNS Server" uses
```

### Order of evaluation

codeopt builds the selection in this order. **Later steps override earlier ones:**

1. Everything is unselected.
2. `settings.preset` selects its starting set.
3. `[categories]` switches whole tabs on or off.
4. `[tweaks]` `enable`, `disable` and single `id = true/false` keys, in file order.
5. `[dns]` selects and configures **Set DNS Server**.
6. `settings.restore_point` forces the restore point on or off.

For example, `preset = "all"` followed by `disable = ["remove_xbox_apps"]` gives you everything except the Xbox removal.

### Supported TOML syntax

codeopt has its own lightweight TOML reader that covers everything templates need:

| Feature | Example |
|---|---|
| Comments (whole line or end of line) | `# note` · `preset = "fps"  # note` |
| Strings, double or single quoted | `"Competitive"` · `'C:\no\escapes\here'` |
| Escapes in double-quoted strings | `"line\tTab"` · `"C:\\path"` |
| Booleans (lowercase) | `true` · `false` |
| Integers (underscores allowed) | `240` · `1_000` |
| Arrays, also spread over several lines, trailing comma allowed | `["a", "b",]` |
| Section headers | `[settings]` |

**Not supported:** inline tables `{ }`, arrays of tables `[[ ]]`, multi-line strings `""" """` and dates. Use the plain forms above instead.

Section and key names are **case-insensitive**. Tweak IDs are normalized, so `disable-core-parking`, `Disable_Core_Parking` and `disable_core_parking` are all the same ID.

---

## 4. `[template]`

Information only. It's shown in the codeopt header and doesn't change behaviour.

| Key | Type | Description |
|---|---|---|
| `name` | string | Shown as `TEMPLATE <name>`. If missing, the file name is used |
| `author` | string | Shown as `by <author>` |
| `description` | string | Free text for readers of the file |
| `version` | string | Free text |
| `created` | string | Free text, filled in by **E** export |

You can add any other keys here and they're ignored.

---

## 5. `[settings]`

| Key | Type | Default | Description |
|---|---|---|---|
| `preset` | string | `"none"` | Starting selection, see the table below |
| `restore_point` | bool | none | `true` always creates a restore point first, `false` never does. Applied last, so it overrides everything else |
| `restart` | string | `"ask"` | What to do after applying if a tweak needs it: `"ask"` (Y/N prompt), `"never"` (only print a message), `"always"` (restart or sign out automatically after 5 seconds) |
| `auto_apply` | bool | `false` | `true` skips the menu and applies right away (same as `--apply`) |
| `confirm` | bool | `true` | `false` skips the confirmation screen and pauses (same as `--yes`) |
| `base_fps` | integer | hardware estimate | Your real in-game FPS. Every FPS estimate is calculated from it (same as pressing **F** in the menu) |
| `language` | string | see section 5.1 | Interface language: `"en"` or `"pl"`. Template warnings are shown in this language too |

### Presets

| Preset | Selects |
|---|---|
| `none` | Nothing. Build the selection with `[categories]` and `[tweaks]` |
| `recommended` | Every tweak marked **REC** in the menu (same as the **R** key) |
| `fps` | Restore point plus every `+FPS` tweak whose estimated gain **on this PC** is above zero and that doesn't lower security. The result changes with the hardware: for example, *Disable VBS* is never included, and *Disable Memory Compression* is skipped on 8 GB machines |
| `privacy` | Restore point plus the whole **Privacy** tab |
| `all` | Every tweak. Use carefully: it includes OneDrive removal, Xbox app removal and disabling VBS |

### 5.1 Language

codeopt is available in **English** and **Polish**. Tweak names, descriptions, tags, FPS reasons, DNS notes, warnings and the `--help` text are all translated. It picks the language in this order:

1. `--lang` on the command line
2. `language` in the template's `[settings]`
3. The language you last chose with **L** in the menu (saved in `HKCU\Software\codeopt`)
4. The Windows display language: Polish Windows starts in Polish, everything else in English

Press **L** in the menu at any time to switch between PL and EN. The banner shows the current language, for example `v2.1 • PL`.

> **Template files are always written in English**, whatever the interface language. Section names, keys, tweak IDs, category names (`gaming`, `network`, ...), presets and DNS provider IDs never change, so one template works in both languages. Only the values of `name`, `author` and `description` are free text.

### How restarts work

Every tweak has one of three apply modes. They're shown in the menu on the **Apply** line and listed in section 9:

| Mode | Meaning |
|---|---|
| **Instantly** | Active right after applying |
| **Sign out** | Takes effect after you sign out and back in, or restart |
| **Restart** | Needs a full restart (drivers, boot settings, kernel or network stack) |

After applying, codeopt counts the modes. If any tweak needs a restart, it handles it according to `restart`. If only sign-outs are needed, it offers to sign out instead.

---

## 6. `[categories]`

Switch a whole tab on (`true`) or off (`false`).

```toml
[categories]
gaming  = true
input   = true
debloat = false
```

Category names: `safety`, `power`, `gaming`, `input`, `network`, `privacy`, `system`, `cleanup`, `debloat`.

---

## 7. `[tweaks]`

Pick individual tweaks by ID. There are two styles and you can mix them.

**List style:**

```toml
[tweaks]
enable  = ["ultimate_performance_plan", "disable_core_parking"]
disable = ["disable_hibernation"]
```

**Key style:**

```toml
[tweaks]
ultimate_performance_plan = true
disable_hibernation       = false
```

Keys are processed in file order, so a later line wins over an earlier one. The full list of IDs is in section 9, or run `.\codeopt.ps1 --list`. The menu also shows the ID of the highlighted tweak on the **Apply** line.

---

## 8. `[dns]`

Configures the **Set DNS Server** tweak. Adding a `[dns]` section selects it automatically.

| Key | Type | Default | Description |
|---|---|---|---|
| `enabled` | bool | `true` | `false` unselects the DNS tweak even if a preset selected it |
| `provider` | string | `"cloudflare"` | Provider ID from the table below. Defaults to `"custom"` when `primary` is set |
| `doh` | bool | `true` | `false` sets plain DNS only and doesn't register DNS-over-HTTPS |
| `ipv6` | bool | `true` | `false` sets only the IPv4 servers |
| `primary` | string | none | `custom` only: first server, IPv4 or IPv6 |
| `secondary` | string | none | `custom` only: second server |
| `primary_v6` | string | none | `custom` only: first IPv6 server |
| `secondary_v6` | string | none | `custom` only: second IPv6 server |
| `doh_template` | string | none | `custom` only: DoH URL, for example `"https://dns.example.com/dns-query"` |

The DNS servers are set on every **physical network adapter that is connected**. When the provider supports DoH, codeopt registers its DoH template with Windows (Windows 11 or newer Windows 10 builds) with fallback to plain DNS enabled, so you never lose name resolution.

### Provider IDs

| ID | Name | IPv4 | Notes |
|---|---|---|---|
| `cloudflare` | Cloudflare | 1.1.1.1 · 1.0.0.1 | Fast anycast, privacy-first |
| `cloudflare_malware` | Cloudflare Malware | 1.1.1.2 · 1.0.0.2 | Blocks malware |
| `cloudflare_family` | Cloudflare Family | 1.1.1.3 · 1.0.0.3 | Malware and adult content |
| `google` | Google | 8.8.8.8 · 8.8.4.4 | Very reliable |
| `quad9` | Quad9 | 9.9.9.9 · 149.112.112.112 | Blocks malware, Swiss privacy |
| `opendns` | OpenDNS | 208.67.222.222 · 208.67.220.220 | Phishing protection |
| `opendns_family` | OpenDNS FamilyShield | 208.67.222.123 · 208.67.220.123 | Adult content, IPv4 only |
| `adguard` | AdGuard | 94.140.14.14 · 94.140.15.15 | Blocks ads and trackers |
| `adguard_family` | AdGuard Family | 94.140.14.15 · 94.140.15.16 | Ads, trackers, adult content |
| `adguard_unfiltered` | AdGuard Unfiltered | 94.140.14.140 · 94.140.14.141 | No filtering |
| `controld` | Control D | 76.76.2.0 · 76.76.10.0 | No filtering |
| `controld_malware` | Control D Malware | 76.76.2.1 · 76.76.10.1 | Blocks malware |
| `cleanbrowsing` | CleanBrowsing Security | 185.228.168.9 · 185.228.169.9 | Malware and phishing |
| `cleanbrowsing_family` | CleanBrowsing Family | 185.228.168.168 · 185.228.169.168 | Strict family filter |
| `comodo` | Comodo Secure | 8.26.56.26 · 8.20.247.20 | Malicious sites, IPv4 only, no DoH |
| `auto` | Automatic (DHCP) | none | Resets to your router or ISP DNS |
| `custom` | Custom | your own | Needs `primary` |

> **In the menu:** highlight **Set DNS Server** and press **Space** to open the provider list. codeopt pings every provider from your PC and labels the fastest one. Press **B** to pick the fastest, **T** to test again, **Del** to unselect, or choose **Custom...** to type your own servers.

---

## 9. Tweak ID reference

**Applies** shows when the change takes effect. **Rec.** means the tweak is part of the `recommended` preset.

### Safety

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `create_system_restore_point` | Instantly | yes | SAFE |
| `backup_registry_hives` | Instantly |  | SAFE |

### Power

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `ultimate_performance_plan` | Instantly | yes | +FPS +1% LOWS |
| `disable_core_parking` | Instantly | yes | +FPS -STUTTER |
| `disable_usb_selective_suspend` | Instantly | yes | -INPUT LAG |
| `disable_pcie_link_state_power_saving` | Instantly | yes | +FPS -STUTTER |
| `disable_power_throttling` | **Restart** | yes | +FPS |
| `disable_hibernation` | Instantly | yes | +DISK |
| `disable_fast_startup` | Instantly | yes | +STABILITY |

### Gaming

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `enable_game_mode` | Instantly | yes | +FPS |
| `disable_game_bar_game_dvr` | Sign out | yes | +FPS -STUTTER |
| `disable_fullscreen_optimizations` | Sign out | yes | +FPS -INPUT LAG |
| `optimizations_for_windowed_games` | Instantly | yes | +FPS -INPUT LAG |
| `hardware_accelerated_gpu_scheduling` | **Restart** |  | +FPS -LATENCY |
| `mmcss_game_priority` | **Restart** | yes | +FPS +1% LOWS |
| `cpu_priority_separation` | Instantly | yes | +FPS -INPUT LAG |
| `global_timer_resolution` | **Restart** | yes | -INPUT LAG +1% LOWS |
| `disable_dynamic_tick` | **Restart** |  | -LATENCY |
| `disable_hpet_platform_clock` | **Restart** |  | +FPS -LATENCY |
| `disable_multiplane_overlay_mpo` | **Restart** |  | -STUTTER |
| `disable_vbs_memory_integrity` | **Restart** |  | +FPS -SECURITY |
| `disable_nvidia_telemetry` | Instantly | yes | +PRIVACY -CPU USAGE |

### Input

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `disable_mouse_acceleration` | Sign out | yes | +AIM |
| `mouse_keyboard_data_queue` | **Restart** |  | -INPUT LAG |
| `fast_keyboard_repeat` | Sign out | yes | +RESPONSE |
| `disable_sticky_filter_toggle_keys` | Sign out | yes | NO POPUPS |

### Network

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `disable_nagles_algorithm` | **Restart** | yes | -PING |
| `disable_network_throttling` | **Restart** | yes | -PING |
| `optimize_tcp_stack` | Instantly | yes | -PING +SPEED |
| `disable_adapter_power_saving` | **Restart** | yes | -PING -SPIKES |
| `disable_interrupt_moderation` | **Restart** |  | -PING |
| `disable_large_send_offload` | **Restart** |  | -PING -SPIKES |
| `remove_qos_bandwidth_reserve` | **Restart** | yes | +BANDWIDTH |
| `disable_delivery_optimization_p2p` | Instantly | yes | +BANDWIDTH |
| `set_dns_server` | Instantly |  | +DNS SPEED |
| `flush_dns_arp_cache` | Instantly | yes | FIX |

### Privacy

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `disable_telemetry` | **Restart** | yes | +PRIVACY -CPU USAGE |
| `disable_telemetry_tasks` | Instantly | yes | +PRIVACY -STUTTER |
| `disable_advertising_id` | Instantly | yes | +PRIVACY |
| `disable_activity_history` | Sign out | yes | +PRIVACY |
| `disable_bing_in_start_search` | Sign out | yes | +PRIVACY +UI SPEED |
| `disable_copilot_recall` | Sign out | yes | +PRIVACY +RAM |
| `disable_error_reporting` | Instantly | yes | +PRIVACY |
| `disable_feedback_prompts` | Instantly | yes | +PRIVACY |
| `disable_location_tracking` | **Restart** |  | +PRIVACY |

### System

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `performance_visual_effects` | Sign out | yes | +FPS +UI SPEED |
| `disable_transparency` | Instantly |  | +FPS +UI SPEED |
| `disable_background_apps` | Sign out | yes | +FPS +RAM |
| `remove_startup_delay` | Instantly | yes | +BOOT |
| `instant_menus` | Sign out | yes | +UI SPEED |
| `disable_memory_compression` | **Restart** |  | +FPS -CPU USAGE |
| `keep_kernel_in_ram` | **Restart** |  | -STUTTER |
| `disable_sysmain_superfetch` | Instantly |  | -DISK USAGE |
| `disable_search_indexing` | Instantly |  | -DISK USAGE -CPU USAGE |
| `ntfs_optimizations` | **Restart** | yes | +DISK SPEED |
| `disable_unneeded_services` | Instantly | yes | +RAM |
| `disable_tips_suggestions` | Sign out | yes | +PRIVACY |
| `disable_widgets` | Sign out | yes | +RAM |
| `classic_context_menu` | Sign out |  | +UI SPEED |
| `show_file_extensions` | Instantly | yes | +SECURITY |
| `disable_edge_background_running` | Instantly | yes | +RAM +BOOT |

### Cleanup

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `clean_temp_files` | Instantly | yes | +DISK |
| `clear_shader_caches` | Instantly |  | +DISK FIX |
| `clear_windows_update_cache` | Instantly | yes | +DISK |
| `empty_recycle_bin` | Instantly |  | +DISK |
| `dism_component_cleanup` | Instantly |  | +DISK |

### Debloat

| ID | Applies | Rec. | Impact |
|---|---|---|---|
| `remove_bloatware_apps` | Instantly |  | +RAM +DISK |
| `remove_xbox_apps` | Instantly |  | +RAM |
| `uninstall_onedrive` | Instantly |  | +RAM +BOOT |

---

## 10. Examples

### Competitive gaming

```toml
[template]
name   = "Competitive FPS"
author = "codeopt"

[settings]
preset        = "fps"
restore_point = true
restart       = "ask"
language      = "pl"         # Polish interface

[categories]
input = true

[tweaks]
enable  = ["disable_nagles_algorithm", "optimize_tcp_stack", "clear_shader_caches"]
disable = ["disable_memory_compression"]

[dns]
provider = "cloudflare"
```

### Privacy only, restart later

```toml
[template]
name = "Privacy & Clean"

[settings]
preset  = "privacy"
restart = "never"

[categories]
cleanup = true

[tweaks]
remove_bloatware_apps = true
empty_recycle_bin     = false

[dns]
provider = "quad9"
```

### Unattended with your own DNS (for example Pi-hole)

```toml
[settings]
preset     = "recommended"
auto_apply = true
confirm    = false
restart    = "always"

[dns]
provider  = "custom"
primary   = "192.168.1.2"
secondary = "1.1.1.1"
```

Run it with `.\codeopt.ps1 --template unattended.toml`. It elevates, applies, then restarts with no prompts.

### Minimal: just two tweaks

```toml
[tweaks]
enable = ["disable_game_bar_game_dvr", "disable_mouse_acceleration"]
```

---

## 11. Warnings and errors

codeopt never stops on a template mistake. It skips the bad part, keeps everything else, and shows a **TEMPLATE WARNINGS** screen before the menu opens. The header also shows `N warning(s)`. Messages you may see:

| Warning | Fix |
|---|---|
| `File not found: ...` | Check the path. Put it in quotes if it contains spaces |
| `settings.language must be en or pl` | Use `"en"` or `"pl"` |
| `Line N: cannot read '...'` | That line isn't `key = value` or `[section]`. Often a missing `=` or quote |
| `Invalid value: ...` | Unquoted text. Strings need quotes: `"fps"`, not `fps` |
| `Unknown section [x]` / `Unknown key settings.x` | Typo in a section or key name |
| `Unknown tweak ID 'x'` | Check section 9 or run `--list` |
| `... must be true or false` | Use lowercase `true` or `false`, without quotes |
| `Unknown preset 'x'` | Use `none`, `recommended`, `fps`, `privacy` or `all` |
| `Unknown DNS provider 'x'` | Use an ID from section 8 |
| `Invalid DNS address: x` | Not a valid IPv4 or IPv6 address |

With `--yes` or `confirm = false`, the warnings screen doesn't wait for a key, but warnings still appear. If the file can't be loaded at all, auto-apply is cancelled and the normal menu opens.

---

## 12. Tips

- **Keep a restore point in every template** (`restore_point = true`). It's the easiest way to undo everything.
- Use `preset = "fps"` instead of listing gaming tweaks by hand. It adapts to each PC's hardware.
- Set `base_fps` to your real FPS when sharing results, so the gain estimates mean something.
- Test new templates **without** `auto_apply` first. Open the menu, check the selection, then turn on automation.
- Templates can be shared between Polish and English users without changes. Only the interface language differs.
- Save templates as UTF-8. Notepad, VS Code and the **E** export all do this by default.

# Any issues or suggestions?
Report any bugs/problems/suggestions in issues page
