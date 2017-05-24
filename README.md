# Dominions

Dominions BBS Game with utility for running it without WWIV by Braddock
Gaskill, May 2017.

This repository contains a python script and configuration files for running 
either the original Dominions or the Dominions ][ WWIV BBS Door Games.  It
does not require a WWIV BBS installation.  

The `dominions.py` python command line interface provides a means to install a
new game, process turns, or log in as a user and run the game.  

`ansi2unicode` is a separate utility which converts ANSI graphics characters to
their Unicode UTF-8 equivalents, which allows the games to be played without
loading special VGA fonts or code tables.  It also interprets WWIV "heart code"
color encodings into standard ANSI color codes.

A Dockerfile is included for easily running an ssh game in a Docker container.

## The Two Dominions

Two versions of Dominions are included in ZIP files:

- **DOM500.ZIP** is the original Dominions game by Apocylypse (aka Chris Haisty), with
  modifications by Tarl Cabot, Siroos Afshar, and RiverCity.  It was written in
Turbo Pascal and originally distributed with source code - unfortunately we
have been unable to find the source.  This game is licensed as freeware as long
as no money is charged for distribution.

- **dom2v20b.zip** is the Beta release of Dominions II, a complete
  rewrite/reinvention of the Dominions game by Sean M. Baird in C++.  It is
distributed as shareware with a 21 day trial period, but we have been unable to
contact the original author.  The game does not seem to cease after 21 days, so
it is playable.

## Installation via Docker

```bash
docker build -t dominions1 .
docker run -d -p 2222:22 --name dominions1 dominions1
ssh -p2222 dominions@localhost
# Default password is `conquest`
```


---
