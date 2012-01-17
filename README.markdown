Taken mostly from the [Rinari project](https://github.com/eschulte/rinari)

Usage
_____
Drop find-file-in-project.el into your load path and the command "find-file-in-path" should be available. Start typing the filename you want and it'll try to match it using [ido](http://www.emacswiki.org/emacs/InteractivelyDoThings)

How it works
____________
"find-file-in-project" will try to find either at ".emacs-project" (and default to ".git") and perform a "find" on all files (can be modified by redefining "ffip-include-regex") except those in a path starting with a "." (as in ".git/*", can be modified by redefining "ffip-exclude-regex").