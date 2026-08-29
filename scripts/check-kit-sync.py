#!/usr/bin/env python3
"""Disposable Git integration checks for kitpull and kitpush."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[1]
ALIASES = ROOT / "shell" / "kit-aliases.sh"


def run(
    *args: str | Path,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [str(arg) for arg in args],
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode:
        raise AssertionError(
            f"command failed ({result.returncode}): {' '.join(map(str, args))}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


class KitFixture:
    def __init__(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="kmh-agent-kit-sync-")
        self.root = Path(self.temp.name)
        self.remote = self.root / "origin.git"
        self.seed = self.root / "seed"
        self.clone_count = 0
        run("git", "init", "--bare", "--initial-branch=main", self.remote)
        run("git", "init", "--initial-branch=main", self.seed)
        self._configure(self.seed)
        self._write_baseline()
        run("git", "add", "-A", cwd=self.seed)
        run("git", "commit", "-m", "baseline", cwd=self.seed)
        run("git", "remote", "add", "origin", self.remote, cwd=self.seed)
        run("git", "push", "-u", "origin", "main", cwd=self.seed)

    def close(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def _configure(repo: Path) -> None:
        run("git", "config", "user.name", "Kit Test", cwd=repo)
        run("git", "config", "user.email", "kit-test@example.invalid", cwd=repo)

    def _write_baseline(self) -> None:
        paths = {
            "README.md": "baseline\n",
            "common.txt": "base\n",
            "gbrain-cards/main.md": "main\n",
            "gbrain-cards/rndlog.md": "rndlog\n",
            "projects/ceoloan/AGENTS.md": "ceoloan\n",
            "projects/rndlog/AGENTS.md": "rndlog\n",
        }
        for relative, content in paths.items():
            path = self.seed / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

        aliases = self.seed / "shell" / "kit-aliases.sh"
        aliases.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ALIASES, aliases)
        installer = self.seed / "install.sh"
        installer.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env bash
                set -euo pipefail
                git -C "$(cd "$(dirname "$0")" && pwd)" config --local kmh-agent-kit.agent "$1"
                printf '%s\\n' "$1" >> "$HOME/install.log"
                """
            ),
            encoding="utf-8",
        )
        installer.chmod(0o755)

    def clone(self, agent: str = "main") -> tuple[Path, Path]:
        self.clone_count += 1
        home = self.root / f"home-{self.clone_count}"
        repo = home / "kmh-agent-kit"
        home.mkdir()
        run("git", "clone", self.remote, repo)
        self._configure(repo)
        run("git", "config", "--local", "kmh-agent-kit.agent", agent, cwd=repo)
        return home, repo

    def kit(
        self, home: Path, command: str, *, check: bool = True
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.update({"HOME": str(home), "GIT_TERMINAL_PROMPT": "0"})
        return run(
            "bash",
            "--noprofile",
            "--norc",
            "-c",
            f'. "$HOME/kmh-agent-kit/shell/kit-aliases.sh"; {command}',
            env=env,
            check=check,
        )


class KitSyncTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = KitFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def test_pull_repairs_upstream_fast_forwards_and_installs(self) -> None:
        home, repo = self.fixture.clone()
        _, writer = self.fixture.clone()
        run("git", "branch", "--unset-upstream", cwd=repo)
        (writer / "README.md").write_text("remote update\n", encoding="utf-8")
        run("git", "add", "README.md", cwd=writer)
        run("git", "commit", "-m", "remote update", cwd=writer)
        run("git", "push", cwd=writer)

        self.fixture.kit(home, "kitpull")

        self.assertEqual((repo / "README.md").read_text(encoding="utf-8"), "remote update\n")
        upstream = run(
            "git", "rev-parse", "--abbrev-ref", "@{upstream}", cwd=repo
        ).stdout.strip()
        self.assertEqual(upstream, "origin/main")
        self.assertEqual((home / "install.log").read_text(encoding="utf-8"), "main\n")

    def test_git_bash_installer_dispatches_to_powershell_with_agent(self) -> None:
        fake_bin = self.fixture.root / "fake-bin"
        fake_bin.mkdir()
        scripts = {
            "uname": "#!/usr/bin/env bash\nprintf 'MINGW64_NT-10.0\\n'\n",
            "cygpath": "#!/usr/bin/env bash\nprintf '%s\\n' \"${!#}\"\n",
            "powershell.exe": (
                "#!/usr/bin/env bash\n"
                "printf '%s\\0' \"$@\" > \"$HOME/powershell-args\"\n"
            ),
        }
        for name, content in scripts.items():
            path = fake_bin / name
            path.write_text(content, encoding="utf-8")
            path.chmod(0o755)
        home = self.fixture.root / "windows-home"
        home.mkdir()
        env = os.environ.copy()
        env.update({"HOME": str(home), "PATH": f"{fake_bin}:{env['PATH']}"})

        run(ROOT / "install.sh", "gram17", env=env)

        arguments = (home / "powershell-args").read_bytes().rstrip(b"\0").split(b"\0")
        decoded = [argument.decode("utf-8") for argument in arguments]
        self.assertEqual(decoded[-2:], ["-Agent", "gram17"])
        self.assertIn("-File", decoded)
        self.assertIn(str(ROOT / "install.ps1"), decoded)

    def test_pull_and_push_reject_detached_or_non_main_branch(self) -> None:
        home, repo = self.fixture.clone()
        run("git", "checkout", "--detach", cwd=repo)
        detached = self.fixture.kit(home, "kitpull", check=False)
        self.assertNotEqual(detached.returncode, 0)
        self.assertIn("detached HEAD", detached.stderr)

        run("git", "switch", "-c", "feature", cwd=repo)
        feature = self.fixture.kit(home, "kitpush", check=False)
        self.assertNotEqual(feature.returncode, 0)
        self.assertIn("main 브랜치", feature.stderr)

    def test_pull_rejects_in_progress_git_operation_from_any_directory(self) -> None:
        home, repo = self.fixture.clone()
        merge_head = repo / ".git" / "MERGE_HEAD"
        merge_head.write_text("0" * 40 + "\n", encoding="ascii")

        blocked = self.fixture.kit(home, "kitpull", check=False)

        self.assertNotEqual(blocked.returncode, 0)
        self.assertIn("MERGE_HEAD", blocked.stderr)

    def test_non_main_agent_can_push_only_its_domain(self) -> None:
        home, repo = self.fixture.clone("rndlog")
        forbidden = repo / "projects" / "ceoloan" / "AGENTS.md"
        forbidden.write_text("forbidden\n", encoding="utf-8")
        rejected = self.fixture.kit(home, "kitpush", check=False)
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn("push 범위 밖 변경", rejected.stderr)

        forbidden.write_text("ceoloan\n", encoding="utf-8")
        allowed = repo / "projects" / "rndlog" / "AGENTS.md"
        allowed.write_text("allowed\n", encoding="utf-8")
        self.fixture.kit(home, 'kitpush "rndlog update"')
        remote_text = run(
            "git", "--git-dir", self.fixture.remote, "show", "main:projects/rndlog/AGENTS.md"
        ).stdout
        self.assertEqual(remote_text, "allowed\n")

    def test_main_pushes_all_domains_and_another_clone_pulls(self) -> None:
        home_a, repo_a = self.fixture.clone()
        home_b, repo_b = self.fixture.clone()
        target = repo_a / "projects" / "ceoloan" / "AGENTS.md"
        target.write_text("central update\n", encoding="utf-8")

        self.fixture.kit(home_a, 'kitpush "central update"')
        self.fixture.kit(home_b, "kitpull")

        pulled = repo_b / "projects" / "ceoloan" / "AGENTS.md"
        self.assertEqual(pulled.read_text(encoding="utf-8"), "central update\n")

    def test_push_rebases_non_conflicting_remote_change(self) -> None:
        home_a, repo_a = self.fixture.clone()
        home_b, repo_b = self.fixture.clone()
        (repo_a / "README.md").write_text("from a\n", encoding="utf-8")
        (repo_b / "common.txt").write_text("from b\n", encoding="utf-8")

        self.fixture.kit(home_a, 'kitpush "change a"')
        self.fixture.kit(home_b, 'kitpush "change b"')

        self.assertEqual(
            run("git", "--git-dir", self.fixture.remote, "show", "main:README.md").stdout,
            "from a\n",
        )
        self.assertEqual(
            run("git", "--git-dir", self.fixture.remote, "show", "main:common.txt").stdout,
            "from b\n",
        )
        merge_commits = run(
            "git", "--git-dir", self.fixture.remote, "rev-list", "--merges", "main"
        ).stdout.strip()
        self.assertEqual(merge_commits, "")

    def test_rebase_conflict_aborts_without_losing_local_commit(self) -> None:
        home_a, repo_a = self.fixture.clone()
        home_b, repo_b = self.fixture.clone()
        (repo_a / "common.txt").write_text("remote\n", encoding="utf-8")
        (repo_b / "common.txt").write_text("local\n", encoding="utf-8")
        self.fixture.kit(home_a, 'kitpush "remote side"')

        conflicted = self.fixture.kit(home_b, 'kitpush "local side"', check=False)

        self.assertNotEqual(conflicted.returncode, 0)
        self.assertIn("로컬 커밋은 보존", conflicted.stderr)
        self.assertEqual((repo_b / "common.txt").read_text(encoding="utf-8"), "local\n")
        self.assertEqual(run("git", "status", "--porcelain", cwd=repo_b).stdout, "")
        self.assertFalse((repo_b / ".git" / "rebase-merge").exists())
        self.assertEqual(
            run("git", "--git-dir", self.fixture.remote, "show", "main:common.txt").stdout,
            "remote\n",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
