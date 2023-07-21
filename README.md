This repo contains nix flake that builds openmoonray from [this repo](https://github.com/dreamworksanimation/openmoonray/tree/release)

However, dependency versions were updated compared to official description, everything
seem to work still, however was not extensivelly tested.

this will link with `glibc-2.37`

# Building

just `nix build`

NOTE: **THIS IS A STANDALONE BUILD**

meaning all the tools will work, such as `moonray` and `hd_render` [(see source docs)](https://docs.openmoonray.org/)

BUT

to make hydra delegate work with houdini - it has to be reconfigured to use houdini's own USD  
which is pain

# Examples

```
# first build it
nix build

# then use script provided to initialize shell environment
. ./result/scripts/setup.sh

# download some examples, rdla or usd
# to render rdla
moonray -in /some/file.rdla -out image.exr

# to render usd
hd_render -in /some/usd/file.usd -out image.exr
```


# Notes:

I don't have NVidia cards, so this package does not contain options to build with Cuda+Optix YET.

# Upgrade notes

Overall it seems like a bunch of dependencies may be updated to more modern versions without
a need to change anything in openmoonray repo, however certain problems were discovered:

* `openimageio` at some point introduced forward declarations of Vec and V3f in texture.h that make
  it incompatible with openmoonray's code as is. I think currently i've picked the lates openimageio
  release without that change
* `jsoncpp` literally uses the oldest available release and cannot be updated because openmoonray code
  uses implicit cast from const iterator to non-const one, which was a bug in jsoncpp and was fixed
  in the very next release.
* `usd` of version 23 was causing compilation errors too... do not quite remember the nature of
  those issues...
