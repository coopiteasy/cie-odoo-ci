#!/usr/bin/python3

import argparse
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("out")

    args = parser.parse_args()

    url = "https://gitlab.com/coopiteasy/cie-repositories/-/raw/master/custom-twelve-mutu/repositories-12-test.yml"
    response = urllib.request.urlopen(url)
    data = response.read().decode("utf-8")

    with open(args.out, "w") as fp:
        fp.write(data)


if __name__ == "__main__":
    main()
