# ffmpeg useful notes

### Extract 30 seconds of a video starting at 1 minute

``ffmpeg -i input.mp4 -s 00:01:00 -t 00:00:30 -o output.mp4``

