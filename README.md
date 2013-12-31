Welcome!
========

If there's a feature or anything you think is missing, please either a.) open an issue to request the feature or b.) develop the feature yourself and put in a pull request. Pull requests should be written in the same style as the existing code base.

If you're interested in (and serious about) writing an addons, I'll do what I can to implement the APIs you need. Up until this point I've only been implementing what I've needed.

This source is released under the MIT license (see the <i>LICENSE</i> file).

Compiling
=========

You need Lua, Qt, and either GCC or Clang. Visual Studio might work if you create a project file, but I can't promise to avoid the standard language features it doesn't support. I recommend using MinGW. Set CXXFLAGS and LDFLAGS to add Lua and Qt to your search paths, then run `make` to build.