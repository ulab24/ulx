# Changelog

## Unreleased

## 0.5.0 - 2026-11-10

The chat screen now has numbered panes you jump to with a number key, and `init.lua` plus Lua plugins let you change keys, theme and status segments without waiting for a release.

### Added

- **Numbered panes.** On a terminal of at least 100x24 the side column sits on the left as `[1]-Sessions` (resumable sessions, this one first), `[2]-Plan`, `[3]-Agents` and `[4]-Files`, with the chat as `[0]` and a key-hint bar on the last row. Set `preferences.panesSide` to `"right"` to keep it on the right.
- **Pane keys.** With an empty message box (or in vim NORMAL) `1` to `4` focus a pane and `0` or `esc` return to the chat; `alt+1` to `alt+4` and `alt+0` work even while you type. `tab`/`shift+tab` move between panes, `j`/`k` or the arrows move the selection. Remap them as `keybindings.focusPane1` to `focusPane4` and `focusChat`.
- **Pane actions.** `enter` resumes the session, opens the plan step, opens the agent in the transcript or opens the file's diff; `x` in `[3]-Agents` stops that agent (background agents only; one running inside the turn says to use `esc esc`). The chat area previews the selection as `[0]-Session preview`, `[0]-Plan step`, `[0]-Agent detail` or `[0]-File diff`. With the mouse, click a pane or row (click again to open); the wheel moves the selection.
- **Panes on small terminals.** Below 100x24, `1` to `4` and `alt+1` to `alt+4` open that pane as a popup; `esc` closes it.
- **`init.lua`.** Put Lua in `~/.config/ulx/init.lua` (or name a file with `ULX_INIT_LUA`, or turn it off with `ULX_INIT_LUA=off`) to set `ulx.opt` options over your JSON config, map keys with `ulx.keymap.set`, react to events with `ulx.on`, and recolour theme tokens with `ulx.theme.set`. Lua keys never take a letter or digit you are typing, and a broken `init.lua` leaves ulx working and shows one notice with the file and line.
- **Lua plugins.** A folder in `~/.config/ulx/lua/<name>/` with a `plugin.lua` manifest and an `init.lua` can add keys, events, status segments, panes and dialogs. Plugins get no permission until you grant it with `ulx.plugins.allow` or in the `/lua` popup: `state.read` (titles, plan, files), `commands.run` (slash commands) and `exec` (programs). Lua runs in a sandbox with no file or network access, under time and memory limits, only in the interactive TUI; a plugin that fails three times in a minute is turned off until you restart. `docs/LUA.md` is the reference.
- **Lua on screen.** `ulx.status.add` adds a segment to the hint bar or header, `ulx.pane.add` adds panes `5` to `9`, and `ulx.ui.select`, `ulx.ui.input` and `ulx.ui.popup` open dialogs.
- **`/lua` popup** (or `ctrl+x L`): each plugin's version, requested and granted permissions, state and last error. `g` grants, `d` turns a plugin off or on, `r` reloads, `enter` shows the full error.
- **`ulx lua check|eval|plugins`** check `init.lua` or a plugin without opening the TUI, evaluate an expression in the sandbox, and list plugins; `ulx doctor` has a Lua section that warns but never fails; `ulx config` lists the settings `init.lua` overrides, with the line that sets each.

### Changed

- The side column now appears from 100 columns (it was 120) and sits on the left; its CONTEXT section is gone because the composer's gauge covers it. `sidebar = "on"` also shows it on the empty home screen, `"auto"` shows it once a conversation has something to list, `"off"` never shows it and leaves the digits as text. `ctrl+b` hides and shows it, and still opens run details on a narrow terminal.
- Popups (models, themes, sessions, providers, MCP, shortcuts, provider setup) share one size, about 85% of the width and up to 75% of the height, so lists show more rows on a large terminal.

## 0.4.0 - 2026-11-09

ulx tells ult what it is doing, works as a custom agent in Xcode 27 and Android Studio, and every release now has public release notes.

### Added

- **Release notes for every release.** Each GitHub release now carries its notes, and the whole history is published as a feed that ulab24.com renders. Notes for the earlier releases (0.1.0 to 0.3.6) were written for the history, so none is missing.

- **ulx tells ult what it is doing.** Started inside an ult session (ult sets `ULT_SESSION`, `ULT_TOKEN` and `ULT_SOCKET`, and `ult` is on your `PATH`), ulx reports when a turn starts, when it finishes and when it waits for a permission answer, so ult can show working, finished and blocked, notify you, and resume the session with `ulx --resume`. Nothing is installed or configured, and nothing happens outside ult. See `docs/ULT.md`.
- **`ulx acp` works as a custom agent in Xcode 27 and Android Studio.** See `docs/ACP_IDES.md`.
- ACP model lists: `session/new`, `session/load` and `session/resume` now also return the legacy
  `models` field, built from the same list as the `model` config option, and `session/set_model`
  is handled. Every way of changing the model (`session/set_model`, `session/set_config_option`,
  `_ulx/set_model`) ends in one place that sends `config_option_update`.
- **ACP editor MCP servers are connected.** The `mcpServers` an editor sends (stdio with `env` as an
  array or object, http/sse with `headers`) now run per session next to ulx's own servers, in the
  sandbox, at low autonomy, with tool results scrubbed as before. `mcpCapabilities` advertises
  `http` and `sse`. A name that ulx already configures keeps ulx's server; a server that is invalid
  or cannot connect becomes a notice, never a failed `session/new`.
- ACP: `session/close`, `session/delete`, and `additionalDirectories` (validated, then added to the
  sandbox write roots) are advertised in `sessionCapabilities`. `usage_update` and
  `session_info_update` (title from the first prompt) are sent.
- ACP: Initial `tool_call` updates carry absolute `locations` for file tools.
- ACP: `ulx acp --debug-log <file>` writes a redacted transcript of the protocol traffic to a file.
- `store.Delete` in the session store removes a stored session.

### Security

- On macOS and Windows a cowork's protected folder `.cowork/` and file `COWORK.md` are matched ignoring case, so a tool can no longer write into them by spelling the name `.COWORK/` or `.Cowork/`.

### Changed

- `ulx acp` ignores unknown arguments (one line on stderr) instead of exiting, and accepts `--stdio`.
- A missing provider or API key at `session/new` returns JSON-RPC `-32000` (auth_required) with the
  command to run (`ulx setup` or `ulx set-key`) instead of an internal error.
- Model discovery during `session/new`, `load` and `resume` is limited to 3 seconds; on failure the
  configured model is offered with a notice, and the handshake still succeeds.
- A workspace at the home directory is allowed with a warning instead of refused. The filesystem root
  is still refused. A cwd is trimmed and cleaned, and must still be absolute.
- `authenticate` is accepted as a no-op.

### Not done yet

- `fs/read_text_file` and `fs/write_text_file` are not used, so unsaved editor buffers are not read.
  The file tools hash disk bytes to detect conflicts, so reads and writes must move together.
- `terminal/*` is not used.

## 0.3.6 - 2026-10-22

### Fixed

- The sandbox no longer fails every shell command with "create fallback sandbox runtime: mkdir
  /tmp/ulx-runtime-…: no such file or directory" when the process temp directory (`$TMPDIR` or
  `/tmp`) does not exist. The temp directory is created, and when it cannot be used the per-user
  runtime directory and `/var/tmp` are tried; the error names every directory it tried.
- A cowork chat whose host-delivered MCP server cannot be reached now logs why on each turn
  (`cowork: session access MCP server "<name>" is not available this turn: <reason>`) instead of
  silently running without its tools.

## 0.3.5 - 2026-10-22

### Changed

- Maintenance release; no user-visible changes.

## 0.3.4 - 2026-10-21

### Added

- **Per-session MCP server, env and context from a host** (capability `session-access`). A run
  started with `ulx exec --session-access <id>` listens on a private per-user Unix socket; the host
  delivers, renews and withdraws one MCP server (name, http(s) URL, token), extra env vars and
  context lines with `ulx session-access deliver|withdraw --session <id>` (JSON on stdin). The token
  lives only in that process's memory, is sent as a header on each request (so a renewal applies to
  the next call and a withdrawal fails calls cleanly), and is never printed, logged or written to
  disk. See `docs/SESSION_ACCESS.md`.
- **Per-session access for cowork chats.** Each open chat of a `ulx cowork` has its own in-memory store and
  its own socket, named by the chat's `sessionId` (the one the hub and `_ulx/cowork/call chats` report),
  so a host uses the same `ulx session-access deliver|withdraw --session <sessionId>`. Chats are isolated
  from each other and from other coworks; the access ends with the chat session (archive, stop, destroy),
  and a chat that comes back starts with none. `ulx version --json` gains `capabilitySurfaces`
  (`{"session-access":["exec","cowork"]}`).

### Security

- The session-access socket directory is denied to every sandboxed command (connect, stat and list), on
  Linux and macOS.

## 0.3.3 - 2026-10-21

### Fixed

- `/resume` always opens the session picker.

## 0.3.2 - 2026-10-18

### Added

- **A paired device is told its own expiry.** The `_ulx/pair` and `_ulx/auth` results carry
  `hasExpiry`, `expiresAt` and `daysLeft` (capability `device-expiry`), so an app can say "pair
  again by Friday" before it is refused. A device that never expires says so.
- **Typed notices over ACP** (capability `typed-notices`). A client that sets
  `clientCapabilities._meta["ulx/typedNotices"]` in `initialize` gets ulx's own notices (a deprecated
  saved model, an MCP server left off) as `_ulx/notice` notifications instead of `[ulx warning]` text
  at the start of the reply. Other clients are unchanged. ulx advertises it in
  `agentCapabilities._meta`.
- `ulx cowork list`, `status` and `start --json` carry the cowork's default `profile` and `model`
  (`status` now shows the model a cowork names instead of its profile's own), and
  `ulx cowork model --json` says `"ok": true` like every other cowork command (capability
  `cowork-default`).
- `ulx providers models --json` carries `context_window`, `tool_call`, `reasoning` and
  `input_modalities` for the models a server reports them for, such as a ulx-inference gateway
  (capability `provider-model-details`).
- Named capabilities in `ulx --version --json` for what apps now depend on: `cowork-model`,
  `catalog-ask-base-url`, `provider-model-replaced-by`, `device-expiry`, `provider-model-details`,
  `cowork-default` and `typed-notices`. Check for the name, not for a version number.

### Fixed

- **The notice about a replaced saved model never reached an ACP client** (0.3.1 replaced the model
  but said nothing, so the desktop app and editors never saw why). It is now sent once per session, as
  `_ulx/notice` to a client that opted in and as `[ulx warning]` text to any other, and only while the
  session still runs on the replacement.
- `--base-url https://` (a scheme with nothing after it) was saved as `https://https:/v1`. It is now
  refused like any other text that is not an address, as is a host with a trailing colon.

## 0.3.1 - 2026-10-18

### Fixed

- **A saved model that its vendor has deprecated is replaced for the run.** Only an explicit
  `--model` or `/model` redirected before, so a model written into `config.json` long ago (the old
  defaults `claude-sonnet-4.5`, `gpt-4.1`) kept being sent until the provider refused it. OpenAI,
  Anthropic and Google models now move to the registry's replacement, with a notice: on stderr for
  `ulx exec`, a line at the start of the TUI, and once per session over ACP (so the desktop app and
  editors see it). The config file is not rewritten, and custom or compatible endpoints are left
  alone. See "Deprecated models" in `docs/PROVIDERS.md`.
- **`ulx providers add` and `ulx setup` refuse an address that cannot work, and complete one that
  lacks a scheme.** `127.0.0.1:8080` and `llm.example.com/v1` were saved as typed and failed only when
  the provider was first used. They now become `http://127.0.0.1:8080` and `https://llm.example.com/v1`;
  a plain `http://` to a public host, another scheme or something that is not an address is an error.
- **A spent usage limit no longer says "wait a moment".** The hint under a `rate limit error:` that
  says a usage limit was reached (a 5-hour, weekly or monthly allowance) now says it resets later and
  offers another model or profile; a transient 429 keeps the old hint.

### Changed

- `ulx providers list` and `current` say when the saved model is deprecated and what runs instead
  (`(deprecated: runs as claude-sonnet-5.5)`, and `modelReplacedBy` in `--json`); the saved model is
  still shown as written.
- `ulx setup ulx-inference --base-url <url>` asks the server for its models and uses the first, so no
  model name has to be known beforehand. When the server cannot be asked, the error says to pass
  `--model <id>` and which key variable to check. `ulx providers add` still needs `--model`.

## 0.3.0 - 2026-10-18

### Upgrading

- **New default models and presets.** The catalog now knows the Claude 5.x family (Fable 5.1,
  Opus 5.5, Sonnet 5.5, Haiku 5.5, and Opus 5, Sonnet 5, Opus 4.8, Sonnet 4.6), the GPT-6 and
  GPT-5.6 families (GPT-6.1 Sol, GPT-6 Astra, Sol and Luna, GPT-5.6 Sol, Terra and Luna) and
  Gemini 4 Argon, 3.8 Flash, 3.6 Flash, 3.5 and 3.1 Flash-Lite and 3.1 Pro (preview). New OpenAI,
  Anthropic and Google providers default to `gpt-6.1-sol`, `claude-sonnet-5.5` and
  `gemini-3.8-flash`, and the `smart`, `deep`, `fast`, `large` and `precise` modes use the new
  models (`claude-sonnet-5.5`, `claude-opus-5.5`, `claude-haiku-5.5`, `gemini-4-argon`). A provider
  that names its model in config keeps it. The models the vendors are retiring are marked
  deprecated and move to a replacement with a notice: Claude Opus 4.1 (retired) and Sonnet 4.5
  (retires 2026-11-30), GPT-4 Turbo and GPT-4.1 nano (2026-10-23), GPT-4.1, GPT-4.1 mini, GPT-4o and
  GPT-4o mini (2027-01-14). Gemini 2.5 stays, but Google now serves it only to developers who
  already used it, and `gemini-pro` and `gemini-flash` mean the current Pro and Flash.

- **`/model`, the model popup and `/profiles` no longer save anything.** A model chosen with
  `/model <id>` or in the popup, and a profile switch, now move the running session only. Before,
  they also wrote the profile's active provider and model, so the next session started on it. To
  change what new sessions start on, press Ctrl+D in the `/model` or `/profiles` popup (it asks,
  and saves on Enter), or use `/default profile <name>` or `ulx profiles use <name>`. The
  Recent list is still kept.
- **`/profiles` no longer saves the active profile.** Switching profile in the TUI (`/profiles
  <name>`, the manager, or picking another profile's model in `/model`) now moves that session
  only. Before, it wrote `activeProfile`, so every other session and new window followed. To
  change what new sessions start on, use `/default profile <name>` or `ulx profiles use <name>`.
- **The `/model` and `/profiles` popups look and key differently, outside a cowork too.** Rows
  say `this session` and `ulx default` in words, the footer reads `⏎ this session · ctrl+d ulx
  default`, and Ctrl+D asks before it saves a default. The `/profiles` list shows the provider
  count, the provider names, where each profile applies and its limits on one row, and drops
  the names first when the terminal is narrow.
- **`ulx update` with no flag installs the newest release**, the same as `ulx upgrade`. It was a
  usage error before. `ulx update --check` is unchanged.
- **The TUI checks for a newer release** at most once a day and shows one line at startup. Turn it
  off with `updates.check: false` in your user config or `ULX_NO_UPDATE_CHECK=1`. It never runs in
  `ulx exec`, ACP, stream-JSON or when `CI` is set.
- **Coworks.** A new cowork now writes down the profile that is active when it is created, so a
  later switch of ulx's profile does not move it; a cowork made before this follows ulx's active
  profile until its default is set once. `ulx cowork destroy` keeps the folder and the folder can be
  started again as a new cowork (it was refused before); destroy now prints the command. Inside a
  cowork `Ctrl+X s` and `Ctrl+X p` open the schedule and pairing. A chat that finished while nobody
  looked is `idle` as soon as a client opens it (it stayed `unread` before). A shell command that
  provably writes `.cowork/`, `COWORK.md` or the control directory is denied outright, with no
  prompt. The old chat picker, approvals and memory pickers are replaced by full-screen views.
- **For clients of the hub.** The `chats` reply gains `own` and `effective` per chat, `info` gains
  `default`, `model` is a new read-only operation and `_ulx/cowork/notice` gains `model_changed`
  with `profile`, `provider`, `model` and `own`. All are additions; `model.set` stays host-only.
- **Port.** A machine that already ran a hub (its `remote/` state folder holds the
  certificate, key or paired devices) gets `"port": 8590` written into the user config the
  first time the hub starts after the upgrade, so phones paired earlier keep finding it.
  It is an ordinary setting from then on; nothing changes it by itself. A new install listens
  on 24400 and writes nothing. An explicit `remote.port` is never touched. See `docs/REMOTE.md`.
- **Device expiry.** Devices paired with `ulx cowork pair` now expire after 7 days unused,
  however the hub was started. The first time the new version opens `devices.json` it gives
  each existing cowork device 7 days: from its last use if that was within the last 7 days,
  otherwise (never used, or last used longer ago) 7 days from the upgrade. Nobody is locked
  out by the upgrade itself; a device that stays unused for those days has to pair again.
  Terminal-session devices are unchanged. `ulx cowork remote on` no longer passes
  `--device-ttl`.

### Added

- `ulx cowork`: a background agent with many chats and one shared memory, kept in its own
  folder, that the TUI (and other clients) attach to and leave without stopping it. Start it
  with `ulx cowork start`, reattach with `ulx cowork attach`, and see `docs/COWORK.md`.
- Cowork: Home and data folders are refused as a cowork folder, checked again every time it starts.
  Anything outside the folder needs a grant (`ulx cowork grant`, with `--ro` for read-only); credential folders can never be granted.
- Cowork: Chats run side by side; one needing approval never blocks the rest. Approvals wait for a
  person and are never answered automatically, including after a restart.
- Cowork: Scheduled tasks (`ulx cowork schedule`, `/schedule`): the agent can propose one, but it only
  exists once you approve it. Runs have a time and a cost limit, park approvals, and a task
  is paused after 3 failures in a row.
- Cowork: Memory consolidation keeps a snapshot first, so `ulx cowork memory diff|revert` can undo it.
- Cowork: Phone and desktop clients reach coworks through the remote hub. `ulx cowork pair` makes a
  device that sees coworks only, `ulx cowork remote on|off|status` runs the hub, and grants,
  schedule, stop and destroy stay host-only. Devices paired with `ulx cowork pair` expire after 7 days unused (see Upgrading);
  terminal sessions are unchanged.
- Cowork: After a power cut or reboot, `ulx cowork resume` starts every cowork that was not stopped
  with `ulx cowork stop`, and `ulx cowork unit install` sets that up at boot (systemd user
  unit on Linux, launch agent on macOS). Chats that were mid-turn come back `interrupted`.
- Cowork: Browser and desktop screen-control tools are off unless enabled per cowork
  (`ulx cowork tools`). The cowork shell cannot reach the control sockets.
- Cowork: `ulx cowork chat import` copies a stored conversation (for example one made by the desktop
  app) into a new chat, redacted, without touching the source. Host-only.
- Cowork: A client can list and read a cowork's memory files, also through the hub with read scope
  (`cowork.memory.list`, `cowork.memory.read`); writing stays with the agent.
- Cowork: `ulx cowork notify on|off|status` shows a desktop notification (notify-send, osascript) when
  a chat starts waiting or a scheduled run ends and nobody is attached. The same moments are
  published as `cowork_notice` events, and a hub device gets `_ulx/cowork/notice`.
- Cowork: A control device can upload files into a chat of a running cowork and send one message
  that refers to them, over the existing `_ulx/session/upload.*` and `attach_files`
  methods. Files go to `inbox/remote/<chat>/` in the cowork's folder, are listed to the
  chat as untrusted data, and are removed when the chat ends or the cowork is destroyed.
  No new method; `protocolMinor` is unchanged.
- Cowork: Attached to a cowork, the TUI rings the terminal notifier when a chat you are not looking
  at needs you or finishes a turn. The text is generic and never contains a chat title.
- A Gemini key's models are listed live (`GET /v1beta/models`), like OpenAI and Anthropic. For
  all three, a model your key lists that models.dev does not know yet now appears after the known
  ones, so a new model is usable on the day it ships; OpenAI shows only chat-looking ids.

- **ulx-inference hosted provider.** Add a self-hosted ulx-inference gateway from `/provider` (or
  `ulx providers add ulx-inference --base-url <url>`) with its URL and an API key. It works in any
  profile, lists the models your administrator allowed, and shows your 5-hour, weekly and monthly
  limits wherever OpenCode Go's are shown: `/context`, `/profiles`, `ulx usage report`. The server
  needs the new `GET /v1/usage`; an older one shows as "unavailable".
- The new ulx look. The first row of every screen has a hex that shows the state in
  words (`working 14s` with a blinking hex, `waiting for you`, `previewing nord`,
  `reconnecting 4s`) and is led by `ulx ┃`; the right side reads `path · branch · model · effort`. The welcome and first-run screens draw a hex logo (a compact one under 90 columns)
  that reveals left to right and then blinks its underscore. The status row keeps hints at the
  left and shows cost and a five-cell hex context gauge at the right (eight cells in the
  sidebar); the composer border marker is a hex in the mode's colour; setup and the new-cowork
  wizard show one hex cell per step beside `step N of 6`, and the last setup step shows `>_`
  with a blinking underscore. With `NO_COLOR`, `TERM=dumb`, no terminal or a non-UTF-8
  locale the hexes are `*` and `o` and nothing blinks; `ULX_REDUCED_MOTION=1` holds them
  still. See "The hex mark, colour and motion" in `docs/TUI.md`.
- Model and profile popups with a default. In a cowork, `/model` and `/profiles` open the popups
  (Enter: this chat; Ctrl+D then Enter: the cowork's default; `↺ Follow cowork default`; tags that
  say `this chat` and `cowork default` in words). Outside a cowork the same popups say `this
  session` and `ulx default`, and Ctrl+D saves what new sessions start on. A cowork's model choice
  now names its provider too, so a model of a profile's second provider is no longer built on its
  first. Footers keep `⏎` and `ctrl+d` at 96, 60 and 44 columns.
- Models in a cowork. A cowork has a default profile and model, and a chat can have its own
  without changing the default, the other chats, new windows or ulx's active profile.
  `ulx cowork model`, `ulx cowork start --model`, and in the TUI `/model <id>` and
  `/profiles <name>` (this chat only) and `/default [profile <name>|model <id>]` (the cowork's
  default). A new cowork writes down the profile that was active, so switching ulx's profile
  later does not move it. Profiles and credentials stay in `config.json`; no new config file.
  See "Which model a cowork and its chats use" in `docs/COWORK.md`.
- `ulx cowork destroy` keeps the folder, and the folder can now be started again:
  `ulx cowork start <name>`, `start --workdir <folder>` or the wizard starts a new cowork
  over the files a destroyed one left (before, they were refused as "not empty and not an
  existing cowork"). Chats, grants and the schedule are deleted by `destroy` and are not
  restored. Destroy now says so and prints the command. See "Stopped, destroyed, and
  starting again" in `docs/COWORK.md`.
- Cowork screens in the TUI, full-screen and in the chat strip's style, each opened by its chord
  and closed with `Esc`, at 96, 60 and 44 columns in the dark and the light themes: the chat
  switcher (`Ctrl+X l`), the approvals inbox (`Ctrl+X a`), the memory view (`Ctrl+X y`), the
  schedule list with an add-task form that shows the next three run times as you type the cron
  (`Ctrl+X s`), a card for a task the agent proposed that shows its exact cron, prompt, limits
  and output and saves nothing before you approve, and pairing (`Ctrl+X p`, `/pair`) with the QR
  code, access, countdown and the networks the hub works over, an address-and-code view behind
  `m`, and a list of paired devices. They replace the old pickers. See "Cowork screens" in
  `docs/TUI.md`.
- The approvals inbox answers a request in place with the options the cowork offered. The memory
  view opens files read-only and, when the nightly tidy-up left a snapshot, shows a line diff and
  can put memory back after a confirmation.
- A device paired with `ulx cowork pair` shows its days left: `ulx remote devices` has an EXPIRES
  column and the JSON fields `hasExpiry`, `expiresAt`, `daysLeft` and `expired`, and so does the
  pairing screen.
- Shell completions for every `ulx cowork` subcommand and flag, and for cowork names and chat
  ids, in bash, zsh and fish, through a hidden `ulx cowork __complete` helper. The scripts are
  tested in all three shells; a CI job installs zsh and fish for that.
- `go run ./internal/devtools/coworkframeprobe -out DIR` records real frames from a test cowork
  through a hub as scrubbed JSON-lines files for client test fixtures (pairing, auth, presence,
  attach with `fromSeq`, approvals, notices including `run_finished`, `run_failed` and
  `run_skipped`, memory reads, chat management, errors), and `docs/COWORK.md` "Client contract"
  documents every `_ulx/cowork/call` operation and `_ulx/cowork/notice` with request and reply
  JSON, scopes and error codes. A test fails if an example there is not a recorded frame.
- A pending approval's arguments are available to clients (redacted), so a card can show the exact
  call. A new `seen` op on a chat's socket lets a client say it looked at the chat.

### Fixed

- **Light terminals showed the dark theme's pale colours.** The default `system` theme
  chose its colours before the terminal said whether its background was light, and ignored the
  answer afterwards, so a light terminal kept the pale amber headings, pale green chips and a dark
  selection bar. ulx now applies the terminal's answer (and asks again when the window regains
  focus). Light themes also got darker lines, and `maple`'s strong lines are 3.5:1 on its panel.

### Changed

- Inside a cowork `Ctrl+X s` opens the schedule and `Ctrl+X p` pairing. `/stop` and `/provider`
  still work as commands; outside a cowork the chords are unchanged.
- A chat that finished a reply while nobody looked is `unread`; it now becomes `idle` as soon as a
  client opens it (a device attaching, or a terminal showing it). Before, nothing ever made it
  idle again until its next turn.
- A bash command that provably writes `.cowork/`, `COWORK.md` or the cowork's control directory is
  now denied outright, with no approval offered, like `write_file`: redirections, `tee`, `cp`, `mv`,
  `rm`, `install`, `sed -i`, `dd of=` and the like. A target only known at run time still takes
  the old route (a prompt, then the OS sandbox); `docs/COWORK.md` says where the limit is.
- The hub's default port is 24400 on a new install (see Upgrading).

### Security

- Memory refuses a secret assembled by several appends and a credential-shaped file name.
- `read_file`, `grep`, `glob`, `list_directory` and the create and overwrite step of `write_file`
  and `edit_file` go through a root handle, so a folder swapped for a link after the path was
  checked can no longer lead outside the workspace.
- The cowork's control directory is denied to every tool; an approved write there could have let
  the agent edit its own grants.
- New regression tests cover web content and secrets, pairing codes in logs, `0700` directories,
  swapped links, a link to `~/.ssh` and writes to `.cowork/` and the control directory.

## 0.2.2 - 2026-10-15

### Fixed

- The updater refuses to replace the binary of a running test, so a test can no longer install over itself.

## 0.2.1 - 2026-10-10

### Added

- The TUI tells you when a newer release is available, and `ulx update` installs it.

## 0.2.0 - 2026-10-09

### Security

- Workspace trust is pinned to what was trusted: `ulx trust` records a fingerprint of the
  project's `.ulx/hooks.json`, `plugins/`, `specialists/` and `commands/`, and a workspace
  whose fingerprint has changed (a pull that edits a hook, say) is treated as untrusted
  until you review it and run `ulx trust` again. Workspaces trusted by an older ulx have no
  fingerprint and behave as before until trusted again.
- `ulx update` verifies the release's `checksums.txt.asc` against the ulab24 release key built
  into the binary and checks the archive against the signed list before it extracts or
  installs anything. Before, the `.sha256` file came from the same host as the archive, so
  a compromised release host could replace both. A release without the signed list can no
  longer be installed with `ulx update`.
- A project's `.ulx` config can no longer point a provider that holds a stored or
  environment credential at a different endpoint; the project's value is ignored with a
  warning, so the key cannot be sent to a host the repository chose.
- Specialist isolation and `worktrees clean` run git pinned to the worktree's real admin
  directory with filters, fsmonitor, hooks and attributes disabled, and patches are
  size-bounded and written only through non-symlinked directories.
- Skill installs refuse symlinked `SKILL.md` files, cap file sizes and clone without
  symlinks or non-http(s)/ssh protocols.
- "Known safe" command prefixes no longer accept path-qualified names, `git -c` /
  `--git-dir` style global options or `uniq` output files.
- `serve-remote` validates the token's strength, the daemon bridge applies a remote
  policy, and a `Task` call can no longer be covered by an allow-for-session grant.
- The MCP OAuth callback ignores requests with the wrong state, the updater requires
  https and bounds what it downloads, and dictation downloads bound archive extraction.
- A cloned repository's specialists need workspace trust and cannot replace a built-in.
- Stream-JSON, crash reports and the crash notice redact credentials with the shared
  redactor; the TUI strips terminal control sequences from tool output and shows control
  bytes in approval prompts instead of performing them.
- `serve-remote` locks an address out for five minutes after five failed logins in a
  minute; the pause after each failure only slowed a single connection.
- The sandbox masks the container-engine, systemd and session-bus control sockets, and
  sandboxed commands lose `DBUS_SESSION_BUS_ADDRESS`, `DOCKER_HOST`, `CONTAINER_HOST`,
  `TMUX`, `NPM_TOKEN`, `NODE_AUTH_TOKEN`, `TWINE_PASSWORD` and `HF_TOKEN`. The
  format-on-write formatter gets the same scrubbed environment, and the docs say it runs
  outside the sandbox.
- `read_file` refuses FIFOs and devices instead of blocking, and `swarm_inbox` keeps each
  message on one line so a body cannot print fake entries.
- The sandbox's seccomp filters reject the x32 syscall ABI (which skipped the socket,
  network and ptrace denials), and submodule hooks and config are read-only in the sandbox.

### Fixed

- Stopping the remote hub removes its control socket before it reports stopped, and
  `TestRunningAHubAndPairingADeviceEndToEnd` waits for the connection count instead of
  reading it once (it failed about one run in thirty under load).

### Changed

- The TUI header names the session's profile in front of `model · effort` when the
  config has more than the `default` profile, and the welcome screen has a `Profile`
  row (the compact layout leads its status line with a non-default profile).
- `ulx plugin show` and the plugin lists no longer say a plugin's agents are "not loaded
  yet"; `notLoadedYet` in the JSON now lists only `prompts`.

### Added

New capabilities for ulx desktop, each listed in `ulx --version --json` under
`capabilities` so an app can feature-detect it. All fields are additive and optional.

- **`command-list`**: the local-control op `commands` and the hub method
  `_ulx/session/commands` list every built-in slash command with its `policy`
  (`runnable` or `terminal-only`), `description` and `args` (`kind`, `hint`, `options`,
  `custom`, `current`). The list is generated from the table behind the remote command
  refusals, so the two cannot disagree; `remote.allowedCommands` is already applied.
  Hub protocol minor is now 3 and `capabilities` of `_ulx/hub/info` gains `commands`.
- **`command-choices`**: `model` lists the active provider's models and `effort` the
  efforts the active model supports (none for a model without effort control).
- **`command-busy`**: each entry says whether it may run during a turn (`busyOk`).
  `/effort`, `/rename`, `/style` and `/selfcorrect` can; `/model`, `/compact`, `/turns`
  and `/retry` return `session_busy`, as does every command while a compaction runs.
  Before, `/turns <n>` during a turn answered success and did nothing.
- **`mcp-add-stdin`**: `ulx mcp add --stdin` reads `{"env":{…},"headers":{…}}` so secrets
  stay out of argv. Values are never echoed.
- **`session-mode`**: the permission mode (`ask`, `plan`, `auto`, `unsafe`) is in the
  presence record, the hub's session listing and attach result, `ulx sessions list
  --json` and ACP `session/list` `_meta`, and is announced when it changes, from the
  terminal too: a `mode` message on the local stream and `_ulx/session/mode` on the hub.
  A device still cannot set `auto` or `unsafe`.
- **`presence-title`**: the session title (at most 200 characters, one line, redacted) is
  in the presence record and the hub's listing of running sessions.
- **`mcp-oauth-json`**: `ulx mcp oauth login <server> --json` is a line-oriented event
  stream (`url`, then `done`) with `--timeout`, and ends cleanly when stdin closes or on
  SIGTERM. `logout --json` now also carries `"ok": true`. The stream is now safe to read
  while the command runs (the same name, extended): every line is flushed as written;
  the `url` event carries `state` and `port`; `--no-browser` says the caller opens the
  address; the single final `done` event carries a stable `code` (`timeout`, `canceled`,
  `denied`, `failed`) on failure; a second login to a server that is already signing in
  is refused (`failed`, "already in progress") and the callback listener is closed on
  every ending; and `ulx mcp list --json` gives each OAuth server `signedIn`.
- **`acp-commands`**: `ulx acp` sends `available_commands_update` after `session/new`,
  `session/load` and `session/resume`, and again when the list changes (a model switch
  changes the `model` and `effort` choices, a rename or `/turns` changes `current`).
  Entries are `{name, description, input?: {hint}}` with ulx's description under
  `_meta.ulx` (`policy`, `busyOk`, `args`), built from the same table as the hub's
  `_ulx/session/commands`. An ACP client may run the remote-safe set, with
  `remote.allowedCommands` applied; everything else is `terminal-only`. The new
  extension method `_ulx/session/command` runs a command with the hub's classification,
  busy rules and error codes (`command_not_allowed_remotely` -32013, `session_busy`
  -32020, `invalid_params` -32602). A client that ignores the update works unchanged.

- **OpenCode model metadata**: OpenCode Go and Zen models now show their context window,
  tool, reasoning and image (vision) support in the model picker, setup and `/model`, and
  headless runs, ACP and the TUI use it for the context gauge, compaction and the image
  check, instead of the 200k default and name guessing. The Anthropic-format Go entry
  shares the Go catalog, and a custom profile pointed at `opencode.ai/zen` or
  `opencode.ai/zen/go` resolves to the matching catalog. The data comes from the cached
  models.dev snapshot, so nothing is fetched while you work.
- **Provider usage limits**: with an OpenCode Go key connected, `/context` and
  `ulx usage report` show the 5-hour, weekly and monthly usage with reset times.
  `ulx usage report --json` gains a `providerUsage` array (absent when no provider
  reports usage). A failed lookup shows "unavailable" and never fails the command.
  The layer is provider-agnostic: see "Provider usage limits" in `docs/PROVIDERS.md`.
- **Provider limits per profile**: `/profiles` rows and `/model` headings show a compact
  summary of each profile's provider limits (`5h 40% · wk 74% · mo 83%`; faint, amber for a
  warning, red when exhausted; nothing when a provider reports nothing or fails). `/context`
  and `ulx usage report` now cover every profile, labelled `<Provider> · <profile>` when keys
  differ, with one block for profiles that share a key. Other profiles' limits load in the
  background when `/context`, `/profiles` or `/model` opens, one lookup per distinct key,
  cached 60 seconds. See "Provider usage limits" in `docs/PROVIDERS.md`.
- **Profiles**: provider configuration now lives under named profiles in the user
  config (`activeProfile`, `profilesVersion`, `profiles[]`, each with `name`,
  `activeProvider` and `providers`). The first start of this version moves your existing
  providers unchanged into a profile called `default`, once and automatically, after
  copying the original file byte for byte to `<config>.pre-profiles.bak` (mode 0600).
  No stored key moves: the `default` profile keeps using the bare provider name in the
  credential store. `ulx profiles list [--json]` lists profiles, `ULX_PROFILE` selects one
  for a process, and `ulx doctor` has a `config.profiles` check that warns when the
  migration did not complete. Project config and `ULX_PROVIDER_COMMAND` can still emit
  the flat `providers` shape. The `ulx profiles` commands and `--profile` (next entry)
  create and select further profiles.
  Downgrading: an older ulx does not read `profiles`, so it sees no providers in a
  migrated file until you restore `<config>.pre-profiles.bak`.
- **Profile commands**: `ulx profiles add|use|rename|remove` join `list`, and
  `--profile <name>` works on `ulx providers ...`, `ulx auth ...` and `ulx setup`, also
  before the command (`ulx --profile work providers list`). The profile a command uses is
  `--profile`, then `ULX_PROFILE`, then the file's `activeProfile`, then the first
  profile; an unknown name is an error. `providers add` and `ulx setup <id>` create a new
  profile named with `--profile` (on a machine with no config, next to an active
  `default`); `profiles remove` needs `--yes` and deletes only that profile's stored keys.
  Provider commands print `Added provider N` or `Updated provider N`, their `--json` has
  `created`, and every provider-command JSON payload has `profile`. `ulx exec` keeps its
  legacy `--profile <model-profile>` flag (accepted and ignored), so name the provider
  profile before it (`ulx --profile work exec ...`) or use `ULX_PROFILE`; sub-agents and
  swarm members inherit the profile: every `exec` and interactive run with a provider
  exports `ULX_PROFILE` (also when it is `default`) to its child processes, including the bash
  tool, MCP servers and nested `ulx`. The interactive TUI saves model choices, provider
  edits, added providers and first-run setup into the session's profile, so
  `ulx --profile work` keeps them in `work`.
- **Clearer `/context` provider limits**: one `Provider limits` heading, then a sub-block per
  provider and profile (`<provider> · <profile>`, in blue) with the
  meters in aligned rows beneath it, instead of one flat list where the profile name looked
  like another meter.
- **`/profile` opens the profile manager**: typed bare, `/profile` now opens the same
  popup as `/profiles`. `/profile status`, `balanced`, `fast` and `thorough` keep their
  execution-profile meaning (the status moved from bare `/profile` to `/profile status`).
- **Profiles in the TUI**: `/profiles` opens a profile manager (provider counts, `●` on the
  session's profile; Enter switches, `n` new, `r` rename, `d` delete with a confirm that
  shows the stored-key count, `a` add a provider to the highlighted profile without
  switching), and `/profiles <name>` switches directly with name completion. A switch is
  refused during a run and for a profile with no usable provider, changes nothing when it
  fails, saves `activeProfile` like `ulx profiles use` and exports `ULX_PROFILE`; a
  startup `ULX_PROFILE` or `--profile` still wins at the next start. `/profile` (execution
  profile) is unchanged. The `/provider` title shows `Providers · profile <name>`, and
  first-run setup on a fresh configuration has an editable `Profile name` (default
  `default`, typed not pasted, up to 24 characters: typing more clears the field and
  shows a message, so a name is never partially kept). `/profiles` is terminal-only, like
  `/provider`.
- **Multi-profile `/model` picker**: with two or more profiles that have usable models,
  `/model` groups every profile's models under headings (profile name, provider faded,
  the session's profile first); with one profile it looks as before. The other profiles
  load in the background, each discovered with its own credentials, and one that fails to
  load is named in the picker's note. Picking a model under another profile switches
  profile, provider and model together and saves `activeProfile` like `/profiles` Enter;
  it is refused during a run and changes nothing when it fails. Recents remember their
  profile (an older recent belongs to the session's profile; one whose profile is gone is
  hidden). Renaming a profile moves its cached model lists to the new name; deleting one
  drops them.

Sub-agents (specialists):

- **Parallel `Task` calls**: when the model asks for several read-only specialists in one
  turn (several `explorer` runs, say), they now run side by side, at most 4 at once, instead
  of one after another. A specialist that can write, a resume, or an unknown name still asks
  first and runs alone.
- **Specialist limits**: a specialist file can set `maxTurns` (1 to 500), `disallowedTools`
  (tool names removed from what `tools` granted; an extending specialist keeps its base's
  denials) and `permissionMode: read-only`, which pins the child to read-only autonomy even
  under an unsafe parent. It can only narrow what the parent grants. These apply to resumed
  runs too.
- **Report cap**: what a specialist hands back to its parent is cut at 32 KiB, with a
  notice naming the session to resume for the rest.
- **Isolated specialists**: `isolation: worktree` in a specialist file, or `isolation` on the
  `Task` call, runs the child in its own git worktree. When it finishes, its changes are
  saved as `.ulx/worktree-patches/<session>.patch` (a background run also writes
  `<session>.report.txt`) and the result lists the changed files. Apply the patch with
  `git apply`, which is all or nothing. This is what makes several writing specialists safe
  to run at once. The child starts from your last commit, so uncommitted edits are not
  visible to it. A worktree that holds changes is never removed automatically; the result
  prints the `git worktree remove` command.
- **Plugin agents**: the `agents/*.md` files of enabled marketplace plugins now load as
  specialists named `<plugin>-<agent>`, after the same integrity check as skills. A built-in
  or your own specialist wins any name clash. Files written for Claude Code load too: a
  comma-separated `tools` line is read and its tool names mapped, `model: inherit` and
  models ulx does not know fall back to the parent's, and its `permissionMode` values are
  ignored. Everything dropped is listed in the specialist's warnings. See
  [MARKETPLACE.md](docs/MARKETPLACE.md#agents-written-for-claude-code).
- **`specialist-progress`**: a sub-agent's steps now reach the parent's stream. Stream-JSON
  gains a `tool_progress` event (the `Task` call's `id`, and `meta.childType`, `childTool`,
  `childSession`), and ACP sends `tool_call_update` messages for the call, with the step as
  JSON under `_meta["git.ulab24.com/ulab24/ulx/childProgress"]`. Only tool names are
  reported, never arguments, output or the child's text. Existing events are unchanged.
- **Phase skills**: `skills/plan-phases`, `skills/run-phases` and `skills/review-phase` teach
  the model to split a large task into a plan, run the phases through specialists (in
  parallel, each in its own worktree), check every result itself, and gate patches on
  review. Install them with `ulx skills add ./skills/<name>`. See
  [EXTENDING.md](docs/EXTENDING.md#plan-and-run-work-in-phases).
- **`ulx exec --worktree --resume`** returns to the worktree the session ran in, from any
  directory. It refuses a session that never used a worktree, a different `--worktree`
  name or `--worktree-dir`, and a worktree that has been cleaned up, and an unknown session
  id is now reported before a worktree is created. Trust for project hooks, MCP servers and
  plugins comes from that worktree's own repository.

### Fixed

- **Resuming a specialist** (`Task` with `resume`) never worked: its session was refused as
  "not resumable". An explicit `--resume <id>` may now continue a specialist's session. A
  bare `--resume` and the pickers still skip it.
- **`ulx exec --resume` from another directory** used to continue the conversation in the
  wrong place without a word. A session that ran in a ulx worktree is now refused unless you
  pass `--worktree`, and any other change of directory prints a warning.
- **`--worktree` with `--resume`** used to create a new worktree from `HEAD` and resume the
  conversation into it, without the session's edits.
- **`ulx specialist edit` and `delete`** on a plugin's agent said only "not found". They now
  say which plugin owns it.

## 0.1.10 - 2026-10-05

### Added

- Provider profiles, provider usage limits, and the last ulx desktop contract additions. The full notes are under 0.2.0, which collected them.

## 0.1.9 - 2026-10-04

### Added

- Capabilities for ulx desktop: the command list and its choices, busy rules, `ulx mcp add --stdin`, session mode, presence title and `ulx mcp oauth login --json`. The full notes are under 0.2.0, which collected them.

## 0.1.8 - 2026-10-03

### Added

- **Local control.** An app of the same user on the same machine (ulx desktop) can
  now control any live terminal session over its own socket, with no pairing, token,
  TLS or `/remote`. It gets exactly the limits of a paired device with control (allow
  once or deny, ask or plan only, allowlisted commands, first answer wins), plus
  uploads and attach. `send` during a turn answers `busy` instead of queueing.
  Authentication is the file system: a 0700 directory, a 0600 socket, a peer uid check
  on every connection, and ownership and symlink checks before the socket is served.
  See [docs/REMOTE.md](docs/REMOTE.md#local-control), including the threat model.
- **Pausing it.** `remote.localControl` in the config (default `true`), a **Local
  control** row in `/remote`, `--no-local-control` and `ULX_LOCAL_CONTROL=0`. Off keeps
  mirroring and answers control with `control_paused`, at once, for attached
  controllers too. Presence records carry `controlPaused`.
- A quiet footer line while a local controller is attached.
- **Session origin.** Sessions record where they were created (`tui`, `desktop-cli`,
  `desktop-cowork`, or `other`); ACP `session/new` reads it from `_meta.origin`. Sessions
  from before this are `tui`. `ulx sessions list --json`, ACP `session/list` and presence
  records report `origin`, `cwd`, `title`, `updatedAt`, `live`, `controllable` and
  `controlPaused`.
- The resume picker, the welcome and command-center lists and `ulx exec --resume` skip
  `desktop-cowork` sessions by default; `--all` shows them.
- `ulx --version --json` reports `capabilities`, including `local-control` and
  `session-origin`.

### Fixed

- A paired device or local controller sending the command `compact` with no argument no
  longer crashes the session (an index past the end of an empty word list in the remote
  command policy).

## 0.1.7 - 2026-10-03

### Added

- Files can be uploaded and attached to a session (attachment upload).

## 0.1.6 - 2026-10-02

### Added

- Remote control: a paired device can control a session, and the TUI shows and manages it.

## 0.1.5 - 2026-10-02

### Added

- Remote access: reach a ulx session from another device.

### Fixed

- Copying from popups in the TUI works again.

## 0.1.4 - 2026-10-01

### Added

- Plugin marketplace.
- In vim mode, Enter sends the message.

### Fixed

- The skill marketplace loads again, and the cursor colour is correct.

## 0.1.3 - 2026-10-01

### Added

- Vim mode supports commands.
- Tab suggestions in the composer, and the features ulx desktop needs.

## 0.1.2 - 2026-10-01

### Added

- A `composer.lines` preference (also `ULX_COMPOSER_LINES` and `/composer lines`) draws multi-line drafts as a rail, a bar or with line numbers, and long drafts scroll with a count of hidden rows.
- `/vim` and `/composer` open pickers, and ulx says when vim mode overrides `composer.lines`.

## 0.1.1 - 2026-10-01

### Changed

- The TUI footer was refreshed.

## 0.1.0 - 2026-09-30

First release of ulx, the AI coding agent for your terminal.

### Added

- A redesigned TUI: timeline rail with status glyphs, boxed diffs with a running-command timer, a command drawer above the composer, a permission card with a risk chip, an ask-user questionnaire, modal pickers for models, themes and sessions, a provider manager, a tabbed MCP manager, an optional sidebar, an optional vim mode for the composer, and a welcome screen.
- A first-run setup wizard: provider list with status, credential choices with a connection test, model list and safety choice.
- Light and dark themes checked across terminal widths.
- Releases are published on GitHub, and `ulx` can update itself from them.
