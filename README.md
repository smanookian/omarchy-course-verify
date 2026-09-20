# omarchy-course-verify

A read-only health check for the [Stevinator free Omarchy course](https://stevinator.com/courses/omarchy).

Every check mirrors a real item from the course's own Module 0 Checkpoint and later modules: is Omarchy installed, is the bootloader reachable, does networking/audio/Bluetooth work, is Git/GitHub CLI/mise set up, are there any failed systemd units, is snapshot tooling present.

## Why this exists

The course used to ask you to self-report a checklist ("I did this ✓"). This script actually runs the checks instead — the same commands the course already teaches you to run yourself (`omarchy version`, `bootctl status`, `systemctl --failed`, `gh auth status`, `mise --version`, etc.), just collected in one place.

## What it does — and doesn't — do

- **Read-only.** Every check is a status/version/info query. Nothing here installs, modifies, or deletes anything on your system.
- **No network calls.** It only inspects your local machine.
- **No `curl | bash`.** Download it, read it, then run it yourself. That's deliberate — this is a script that touches your system, and you shouldn't run code you haven't looked at, from us or anyone else.

## Usage

```bash
curl -O https://raw.githubusercontent.com/smanookian/omarchy-course-verify/main/verify.sh
chmod +x verify.sh
./verify.sh
```

### Verify the download first (optional, recommended)

If you'd rather check the file's integrity before running it:

```bash
curl -O https://raw.githubusercontent.com/smanookian/omarchy-course-verify/main/verify.sh.sha256
sha256sum -c verify.sh.sha256
cat verify.sh          # read it before you run it
```

Exit code is `0` if every check passed, `1` otherwise — safe to use in your own scripts if you want.

### About the "partial report" note on Firmware

The script never asks for `sudo` — that's intentional, it should be safe to run without elevated privileges. `bootctl status` needs root to read a couple of boot-partition files it doesn't strictly need for this check, so as a normal user you'll see a "partial report" note even when your boot is completely healthy. If you want the full `bootctl` output yourself, run `sudo bootctl status` directly.

## License

MIT. See [LICENSE](./LICENSE).
