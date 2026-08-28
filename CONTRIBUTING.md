## Reporting bugs

Rose-chan is built on [4chan X](https://github.com/ccd0/4chan-x) by [ccd0](https://github.com/ccd0), so bug reports go to one of two trackers:

- **Rose-chan** — anything to do with the Rosé Pine themes, the animation layer, the Theme settings tab, the site, or this build in general: **https://github.com/DAEMON-404/rose-chan/issues**
- **4chan X (upstream)** — anything you can also reproduce on stock 4chan X: **https://github.com/ccd0/4chan-x/issues**

Not sure which it is? Install stock 4chan X from https://www.4chan-x.net/builds/4chan-X.user.js and try to reproduce the bug there. Rose-chan keeps the 4chan X script name, so that install replaces Rose-chan rather than running beside it; reinstall from https://daemon-404.github.io/rose-chan/ when you're done. If it still isn't clear, report it on the Rose-chan tracker and it will be routed.

You can submit a bug report / feature request via your Github account.

If you're reporting a bug, the more detail you can give, the better. If I can't reproduce your bug, I probably won't be able to fix it. You can help by doing the following:

1. Include precise steps to reproduce the problem, with the expected and actual results.
2. Make sure your browser, Rose-chan, and userscript manager (e.g. Greasemonkey, ViolentMoney, or Tampermonkey) are up to date. **Include the versions you're using in bug reports.** Rose-chan installs under the name 4chan X and replaces an existing 4chan X install rather than running alongside it, so quote the version string from the settings panel and say that you are on Rose-chan.
3. Open your console with Shift+Control+J (⇧⌘J on OS X Firefox, ⌘⌥J on OS X Chromium), and **look for error messages**, especially ones that occur at the same time as the bug. Include these in your bug report. If you're using Firefox, be sure to check the browser console (Shift+Control+J), not just the web console (Shift+Control+K) as errors may not show up in the latter. Messages about "Content Security Policy" are expected and can be ignored.
4. If other people (including me) aren't having your problem, **test whether it happens in a fresh profile**. Here are instructions for [Firefox](https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-firefox-profiles) and [Chromium](https://developer.chrome.com/devtools/docs/clean-testing-environment).
5. **Please mention any other extensions / scripts you are using.** To check if a bug is due to a conflict with another extension, temporarily disable any other extensions and userscripts. If the bug goes away, turn them back on one by one until you find the one causing the problem.
6. To test if the bug occurs under the default settings or only with specific settings, back up your settings and reset them using the **Export** and **Reset Settings** links in the settings panel. If the bug only occurs under specific settings, upload your exported settings to a site like https://paste.installgentoo.com/, and link to it in your bug report. If your settings contains sensitive information (e.g. personas), edit the text file manually.
7. Test if the bug occurs using the **native extension** with Rose-chan disabled. If it does, it's likely a problem with 4chan or your browser rather than with the script.

## Development & Contribution

### Get started

- Install [git](https://git-scm.com/), [node.js](https://nodejs.org/), [npm](https://www.npmjs.com/) (usually distributed with node), and GNU Make (on Windows, the [MinGW](http://www.mingw.org/) port will work, and the [GnuWin](http://gnuwin32.sourceforge.net/) port has been reported to work as well).
- Clone Rose-chan: `git clone https://github.com/DAEMON-404/rose-chan.git`<br>(If this is taking too long, you can add `--depth 100` to fetch only recent history.)
- Open the directory: `cd rose-chan`
- Fetch needed dependencies with: `npm install`

### Build

- Build with `make`.

### Contribute

- Rose-chan, like the 4chan X codebase it is built on, is mostly written in [CoffeeScript](http://coffeescript.org/). If you're already familiar with Javascript, it doesn't take long to pick up.
- Edit the sources in the src/ directory (not the compiled scripts in builds/).
- Fetch needed dependencies with: `npm install`
- Compile the script with: `make`
- Install the compiled script (found in the testbuilds/ directory), and test your changes.
- Make sure you have set your name and email as you want them, as they will be published in your commit message:<br>`git config user.name yourname`<br>`git config user.email youremail`
- Commit your changes: `git commit -a`
- Open a pull request by doing any of the following:
  - Fork this repository on Github, push your changes to your fork, and make a pull request through the Github website.
  - Push your changes to any online Git repository, and send an email with an explanation of your changes and the URL, branch, and commit you want me to pull from.
  - Export your changes via `git bundle` (e.g. `git bundle create file.bundle master..your-branch`), and upload them to a file host. Then send an email with an explanation of your changes and the URL of the file.

Pull requests to archive.json should be sent to https://github.com/4chenz/archives.json
The script updates from there automatically.

### More info

Further documentation for the underlying codebase is in upstream's wiki: https://github.com/ccd0/4chan-x/wiki/Developer-Documentation. It describes 4chan X, not Rose-chan's additions, and is maintained by ccd0 — do not open Rose-chan issues there.

4chan X is MIT licensed and Rose-chan keeps that licence. Rose-chan is not affiliated with, nor endorsed by, ccd0 or the 4chan X project.
