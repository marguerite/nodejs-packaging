## Npkg, the ultimate nodejs packaging toolkit

It's so stupid that everyone can package nodejs modules for openSUSE!

* copy `/usr/share/npkg/template` to your package's namespace as <packagename>.spec
* finish the specfile
* run `npkg <module>` inside the package's namespace, it will generate:
* A `<name>.license`, use it to replace the specfile's License tag.
* A `<name>.source`, use it to replace the specfile's Source tag.
* all the dependencies downloaded in current directory. `osc add *.tgz` will add them all!
* A `<name>.json`, add it as Source0

`osc vc` to write some changelog items and `osc ci` to submit! everything works!

