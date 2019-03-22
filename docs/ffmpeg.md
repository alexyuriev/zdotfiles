# ffmpeg : useful notes

Most of these notes are a result of research to make videos stored on local storage
play on the 2nd generation Chromecast ( using catt ). It is presumed that the videos
are playable using a local player such as mpv or VLC.

1) Always use a modern ffmpeg. These notes are based on ffmpeg 4.1.1

2) Sometimes converstion from .mkv to .mp4 fails on ffmpeg 4.1.1. It is a
known regression.  If that's the case, use an older ffmpeg ( such as the one
is likely to be in the distribution ) to first convert .mkv to .mp4

3) Position of stream control arguments matters!


### Extract a section from a file.

Extracts 30 seconds of a video from input.mp4 starting at 1 minute and
writes the result to output.mp4

``ffmpeg -i input.mp4 -ss 00:01:00 -t 30 output.mp4``

## Downscale video from 4k to 1080p

Downscale 4k video from file 4k.mp4 to 1080p.mp4

``ffmpeg -i 4k.mp4 -vf scale=1920:1080 1080p.mp4``

## Downmux 7.1 to Stereo

Take a video file video7.1audio.mp4 and downmix it to video2channel.mp4

``ffmpeg -i video7.1audio.mp4 -vcodec copy -ac 2 -strict 1 video2channel.mp4``

## Make 4K BlueRay 7.1 video playable on 1080p stereo

``ffmpeg -i 4k.br7.1.mp4 -vf scale 1920:1080 -ac 2 -strict 1 1080p.mp4``
