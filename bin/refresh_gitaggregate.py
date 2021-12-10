#!/usr/bin/python3

import os
import subprocess


def main():
    subprocess.run(["download_repos.py", "/tmp/repos_orig.yml"], check=True)

    subprocess.run(
        ["convert_yaml.py", "/tmp/repos_orig.yml", "/tmp/repos.yml"], check=True
    )

    os.chdir("/src")
    subprocess.run(
        ["gitaggregate", "-c", "/tmp/repos.yml", "--job", "4", "--force"], check=True
    )


if __name__ == "__main__":
    main()
