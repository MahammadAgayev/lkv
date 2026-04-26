## A Fun KV Project
This is based on paper read of super simple structure, https://riak.com/assets/bitcask-intro.pdf

## Principles
- Simplicity and Speed
- A multi purpose db implemented from scratch, the idea is LEARN.
- No compression at first for simplicity.
- A single threaded application combined with IO uring.

## Plan
- Implement minimal ring IO - [DONE]
- Implement minimal storage write - [INPROGRESS]

## Scribble
Original bitcask in file structure:
{crc}{tstamp-32bit}{ksz}{valsz}{key}{val}

A single kv is basically a built maintaining a given folder. let's name a lkv.
