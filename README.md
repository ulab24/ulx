# ulx

ulx is an AI coding agent that lives in your terminal. You describe a task,
ulx reads the code, runs commands, edits files and reports back, and it asks
before it does anything risky. It ships as a single binary.

```
$ ulx
```

opens the interactive TUI. `ulx exec "…"` runs the same agent headless, for
scripts and CI.

This repository carries only what you need to install ulx: the install
script, the release signing key, and the released binaries with their
checksums. Development happens on ulab24's own infrastructure, so there is no
source here. **This is the place to tell us what you think** (see
[Feedback](#feedback)).

## Install

> The first release is not published yet. The command below starts working
> when it is.

```sh
curl -fsSL https://raw.githubusercontent.com/ulab24/ulx/main/install.sh | bash
```

This installs the latest release. Run it again, or run `ulx upgrade`, to
update an existing install. Your configuration and sessions are never touched.

Supported: Linux and macOS on amd64 and arm64. Windows builds are published
with each release as a `.zip`; install one by hand and update it with
`ulx upgrade`.

## First run

```sh
ulx setup     # guided setup: provider, key, model, safety
ulx doctor    # check that everything resolves
```

ulx talks to OpenAI, Anthropic, Google Gemini and OpenCode Go directly, and to
any server that speaks the OpenAI or Anthropic API, which covers gateways and
local inference servers. Inside the TUI, `/help` lists every slash command.

## Verifying downloads

Every release ships a `checksums.txt` signed with ulab24's release key
(`ulab24-release-signing-key.asc`, in this repository). `install.sh` checks
the sha256 sum of everything it downloads, and verifies the signature too
whenever `gpg` is available. To check by hand:

```sh
gpg --import ulab24-release-signing-key.asc
gpg --verify checksums.txt.asc checksums.txt
sha256sum --check --ignore-missing checksums.txt
```

## Feedback

Feedback of every kind is welcome, and
[GitHub Issues](https://github.com/ulab24/ulx/issues) is where it goes:

- **Something broke.** Open an issue with what you ran, what you expected and
  what happened. `ulx --version` and the output of `ulx doctor` help a lot.
- **You want something.** Describe the problem you are trying to solve, not
  only the feature you have in mind.
- **Something felt off.** A confusing prompt, a slow start, a setup step that
  lost you. Small papercuts count, and often they are the most useful reports.
- **You just want to say it works.** That helps too.

Please search the existing issues first and add to one if it fits. Remove API
keys, tokens and private code from anything you paste. For a security problem,
do not open a public issue: use
[private vulnerability reporting](https://github.com/ulab24/ulx/security/advisories/new)
on this repository.

## License

ulx is a ULAB24 product. Copyright © 2026 ULAB24.
