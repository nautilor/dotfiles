#!/usr/bin/env python3
import mopidyartfetch
import mpd
import time
import sys
from PIL import Image, ImageDraw
from os.path import expanduser

EWW_CONFIG = "%s/.config/eww" % expanduser("~")
BLANK_ART = "%s/images/blank.png" % EWW_CONFIG


def get_client(timeout: int, host: str, port: int) -> mpd.MPDClient:
    client = mpd.MPDClient()
    for t in range(timeout):
        try:
            client.connect(host, port)
            return client
        except (ConnectionRefusedError, mpd.base.ConnectionError):
            time.sleep(1)
            if t == timeout - 1:
                print("connection failed", file=sys.stderr)
                sys.exit(1)


def get_uri(song):
    for i in ["x-albumuri", "file"]:
        uri = song.get(i)
        if uri:
            return uri


def add_corners(im, rad):
    circle = Image.new("L", (rad * 2, rad * 2), 0)
    draw = ImageDraw.Draw(circle)
    draw.ellipse((0, 0, rad * 2, rad * 2), fill=255)
    alpha = Image.new("L", im.size, 255)
    w, h = im.size
    alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
    alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
    alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
    alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
    im.putalpha(alpha)
    return im


def main():
    client: mpd.MPDClient = get_client(30, "localhost", 6600)
    song = client.currentsong()
    uri = get_uri(song)
    path = mopidyartfetch.get_fn(uri)
    if "blank.png" in path:
        path = BLANK_ART
    image: Image = Image.open(path)
    image = add_corners(image, 20)
    if not path.endswith(".png"):
        path += ".png"
    image.save(path)
    print(path)


if __name__ == "__main__":
    main()
