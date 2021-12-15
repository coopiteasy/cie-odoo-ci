#!/usr/bin/python3

import argparse
import logging
import re

import yaml


def convert_from_ssh_to_https(url):
    """Convert 'git@github.com:account/repo' to 'https://github.com/account/repo'."""
    if not url.startswith("git@"):
        raise ValueError()
    url = url.replace("git@", "")
    url = url.replace(":", "/", 1)
    url = "https://{}".format(url)
    return url


def convert_all_ssh(config):
    for addon_dir in config:
        remotes = config[addon_dir]["remotes"]
        for key, value in remotes.items():
            try:
                remotes[key] = convert_from_ssh_to_https(value)
            except ValueError:
                logging.error("Failed to convert %s", value)


def remove_all_private(config):
    to_remove = set()
    for addon_dir in config:
        remotes = config[addon_dir]["remotes"]
        for value in remotes.values():
            if "private-module" in value:
                to_remove.add(addon_dir)
    for addon_dir in to_remove:
        config.pop(addon_dir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("in_", metavar="in")
    parser.add_argument("out")

    args = parser.parse_args()

    with open(args.in_) as fp:
        config = yaml.safe_load(fp)

    convert_all_ssh(config)
    remove_all_private(config)

    with open(args.out, "w") as fp:
        yaml.dump(config, fp)


if __name__ == "__main__":
    main()
