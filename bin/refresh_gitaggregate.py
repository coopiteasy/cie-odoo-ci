#!/usr/bin/python3

import os
from pathlib import Path
import subprocess


def main():
    subprocess.run(["download_repos.py", "/tmp/repos_orig.yml"], check=True)

    subprocess.run(
        ["convert_yaml.py", "/tmp/repos_orig.yml", "/tmp/repos.yml"], check=True
    )

    # Set the correct config values for gitaggregate to function.
    subprocess.run(
        ["git", "config", "--global", "user.name", "Coop IT Easy"], check=True
    )
    subprocess.run(
        ["git", "config", "--global", "user.email", "gitaggregate@coopiteasy.be"],
        check=True,
    )
    subprocess.run(["git", "config", "--global", "pull.rebase", "false"], check=True)

    Path("/src").mkdir(parents=True, exist_ok=True)
    os.chdir("/src")
    subprocess.run(
        ["gitaggregate", "-c", "/tmp/repos.yml", "--job", "4", "--force"], check=True
    )


if __name__ == "__main__":
    main()
