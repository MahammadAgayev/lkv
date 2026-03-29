## A Fun KV Project
This is based on paper read of super simple structure, https://riak.com/assets/bitcask-intro.pdf

## Principles
- Simplicity and Speed

## Plan
Goals:
- A multi purpose db implemented from scratch, the idea is LEARN.
- No compression at first for simplicity.
- A single threaded application combined with IO uring.

## Scribble
Original bitcask in file structure:
{crc}{tstamp-32bit}{ksz}{valsz}{key}{val}

let's implemenetttt.

A single kv is basically a built maintaining a given folder. let's name a lkv 640630
