## nodejs-packaging

nodejs packaging helpers and utilities for openSUSE.

There's an existing one written by Fedora maintainers, I know.

But they have a different policy compared with openSUSE: They split every nodejs module into a single package.

We have tried this policy for `npm` once in 13.2 era but failed.

Because:

* nodejs modules are huge in number. Even `mkdir -p` function can have a module called `mkdirp`.

* any single module relies on many other modules. eg: npm has 200+ modules in total. 

* modules get updated too often

* upstream implemented a mechanism that a module can hold its dependencies in local "node_modules" at fixed version (old version I mean). 

So actually to break modules into single packages is simply not encouraged. eg:

A needs nan 0.8, B needs nan 2.1. While in npm system both of them can hold their own versions of nan, in the format of rpm package we need to move all their local dependencies to the global namespace, resulting conflicts that are almost impossible to solve. (in nodejs version scheming, the first number means "big change". Although not every developer respects that, but you're a dead person if you meet one.)

So Fedora maintainers implemented a file called multivers. but actually there're too many such cases because anyway upstream implemented that local dependency system, it can be any module. We just shouldn't try to turn the direction "right", or you will end up in porting too many modules, that is like to write the history of registry.npmjs.org

Considering the maintenance also, all current tools lack the function to get all dependencies (I mean, dependencies for dependencies), the ability to auto create packages, and the integration with openSUSE's `osc` tool. We just can't jump to package without knowing how many packages we'll have to deal with in the end, and we can't create 200+ packages by hand, no need to mention an update stack of 200+ packages every week.

So I decide to create this brand new tool, with automatic package creation and bundling of modules taken into consideration. 

A perfect usage scenario might be: 

* packager gives an npmjs.org URL

* it automatically creates the package on openSUSE Build Service, with all its dependencies bundled locally inside its own node_modules directory.

* the local dependencies are ignore in rpm Provides, because they can't be used outside anyway.

* the local dependencies are considered for the package itself in rpm Requires. (get stripped, because it's self fulfilled)

* produced a map of dependency hierachy (like npm-shirnkwrap.json). so packagers can split some common dependencies into another bundle to reduce disk usage. 
