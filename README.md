# translate-subs

A quick and dirty utility to assist with translating SRT files.

Usage:

```
ruby translate.rb [dump|build] [file name]
```

`dump` extracts subtitles and splits them into Google-Translate-paste-friendly
5,000 character long files. You will place translations in files `zh-0.txt`,
`zh-1.txt`, etc.

Then combine translated chunks with `build`.
