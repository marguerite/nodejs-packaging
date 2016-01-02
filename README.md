## nodejs-packaging

nodejs packaging helpers and utilities for openSUSE.

There's an existing one written by Fedora maintainers, I know.

But they have a different policy compared with openSUSE: They split every nodejs module into a single package.

We have tried this policy once during 13.2 era but failed.

Because:

* nodejs modules are huge in number. Even a single `mkdir -p` function can have a module called `mkdirp`.

* any single module relies on many other modules. eg: npm has 200+ modules in total. 

* modules get updated too often

* upstream implemented a mechanism that a module can hold its dependencies in local "node_modules" at fixed version (old version I mean). 

So actually to break modules into single packages is simply not encouraged. eg:

A needs nan 0.8, B needs nan 2.1. While in npm both of them can hold their own versions of nan, in the format of rpm package we need to move all their local dependencies global. 

So Fedora maintainers implemented some file called multivers. but actually there're too many such cases because anyway upstream implemented that local dependency system, we just shouldn't try to turn the direction "right", or you will end up in porting too many modules.

Considering the maintenance also, any current tool lacks the function to get all dependencies (I mean, dependencies for dependencies included), and the ability to auto create packages and integration with openSUSE's `osc` tool. We just can't jump to start packaging without knowing how many packages we'll have to deal with in the end, and we can't create 200+ packages by hand, no need to mention an update stack of 200+ packages every week.

So I decide to create this brand new tool, with automatic package creation and bundle of modules taken into consideration. 

A perfect usage scenario might be: 

* packager gives an npmjs.org URL

* it automatically creates package on openSUSE Build Service, with all its dependencies bundled locally inside its own node_modules directory.

* the local dependencies are ignore in rpm Provides, because they can't be used outside anyway.

* the local dependencies are considered for the package itself in rpm Requires. (get stripped, because it's self fulfilled)

* produced a map of dependency hierachy. so packagers can split some common dependencies into another bundle to reduce disk usage. 
