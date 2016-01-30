## Nova, the ultimate nodejs packaging toolkit like a supernova!

It's so stupid that everyone can package nodejs modules for openSUSE!

* copy `/usr/share/nova/template` to your package's namespace as <packagename>.spec
* finish the specfile
* run `nova <module>` inside the package's namespace, it will generate:
* A `license.txt`, open and paste it to the specfile.
* A `source.txt`, open and paste it to the specfile.
* all the dependencies downloaded in current directory. `osc add *.tgz` will add them all!
* A `install.txt` (not finished yet), open and paste it to the specfile's \%install section

`osc vc` to write some changelog items and `osc ci` to submit! everything ok!

