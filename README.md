# n64chain

This is an edited version of n64chain that just builds binutils and GCC.

Newlib is only built to force gcc to build libstdc++.

While open source, use on other people's computers is a rather unsupported usecase.

build-package.sh is the main script, and it uses `checkinstall` to build .deb packages.

the package descriptions are manually added by me on build from `names.txt`