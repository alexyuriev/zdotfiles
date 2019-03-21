# ffmpeg useful notes

### Extract a section from a file.

Extracts 30 seconds of a video from input.mp4 starting at 1 minute and
writes the result to output.mp4

``ffmpeg -i input.mp4 -ss 00:01:00 -t 30 output.mp4``

