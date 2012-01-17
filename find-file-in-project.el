;;; project-local-variables.el --- Set project-local variables from a file.

;; Copyright (C) 2008 Ryan Davis and Phil Hagelberg

;; Author: Ryan Davis and Phil Hagelberg
;; URL: http://www.emacswiki.org/cgi-bin/wiki/ProjectLocalVariables
;; Version: 0.2
;; Created: 2008-03-18
;; Keywords: project, convenience
;; EmacsWiki: ProjectLocalVariables

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This file allows you to create .emacs-project files that are
;; evaluated when a file is opened. You may also create
;; .emacs-project-$MODE files that only get loaded when you open files
;; of a specific mode in the project. All files for which a
;; .emacs-project file exists in an ancestor directory will have it
;; loaded.

;; It has not been tested in versions of Emacs prior to 22.

(defvar ffip-project-file ".emacs-project"
  "Name prefix for project files.
 Emacs appends name of major mode and looks for such a file in
 the current directory and its parents.")
(defvar ffip-backup-project-file ".git")
(defvar ffip-exclude-regex ".*/\\\..*")
(defvar ffip-include-regex ".*")

(defun plv-find-project-file (dir project-filename)
 (let ((f (expand-file-name project-filename dir))
       (parent (file-truename (expand-file-name ".." dir))))
   (cond ((string= dir parent) nil)
         ((file-exists-p f) f)
         (t (plv-find-project-file parent project-filename)))))

(add-to-list 'auto-mode-alist '("^\.emacs-project" . emacs-lisp-mode))

;;; project-local-variables.el ends here

;;; find-file-in-project.el --- Find files in a project quickly.

;; Copyright (C) 2006, 2007, 2008 Phil Hagelberg and Doug Alcorn

;; Author: Phil Hagelberg and Doug Alcorn
;; URL: http://www.emacswiki.org/cgi-bin/wiki/FindFileInProject
;; Version: 2.0
;; Created: 2008-03-18
;; Keywords: project, convenience
;; EmacsWiki: FindFileInProject

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This file provides a method for quickly finding any file in a given
;; project. Projects are defined as per the `project-local-variables'
;; library, by the presence of a `.emacs-project' file in a directory.

;; By default, it looks only for files whose names match
;; `ffip-regexp', but it's understood that that variable will be
;; overridden locally. This can be done either with a mode hook:

;; (add-hook 'emacs-lisp-mode-hook (lambda (setl ffip-regexp ".*\\.el")))

;; or by setting it in your .emacs-project file, in which case it will
;; get set locally by the project-local-variables library.

;; You can also be a bit more specific about what files you want to
;; find. For instance, in a Ruby on Rails project, you may be
;; interested in all .rb files that don't exist in the "vendor"
;; directory. In that case you could locally set `ffip-find-options'
;; to "" from within a hook or your .emacs-project file. The options
;; accepted in that variable are passed directly to the Unix `find'
;; command, so any valid arguments for that program are acceptable.

;; If `ido-mode' is enabled, the menu will use `ido-completing-read'
;; instead of `completing-read'.

;; Recommended binding:
;; (global-set-key (kbd "C-x C-M-f") 'find-file-in-project)

;;; TODO:

;; Performance testing with large projects
;; Switch to using a hash table if it's too slow

;;; Code:

(defun ffip-project-root ()
  (file-name-directory (or
			(plv-find-project-file default-directory ffip-project-file)
			(plv-find-project-file default-directory ffip-backup-project-file)
			default-directory)))

(defun ffip-uniqueify (file-cons)
  "Set the car of the argument to include the directory name plus the file name."
  (setcar file-cons
	  (concat (car file-cons) " "
		  (cadr (reverse (split-string (cdr file-cons) "/"))))))

(defun ffip-project-files ()
  "Return an alist of all filenames in the project and their path.

Files with duplicate filenames are suffixed with the name of the
directory they are found in so that they are unique."
  (let ((file-alist nil))
    (mapcar (lambda (file)
	      (let ((file-cons (cons (file-name-nondirectory file)
				     (expand-file-name file))))
		(when (assoc (car file-cons) file-alist)
		  (ffip-uniqueify (assoc (car file-cons) file-alist))
		  (ffip-uniqueify file-cons))
		(add-to-list 'file-alist file-cons)
		file-cons))
	    (split-string (shell-command-to-string (concat "find " (ffip-project-root)
							   " -type f \\\( -regex \""
							   ffip-include-regex
							   "\" " 
							   "! -regex \""
							   ffip-exclude-regex
							   "\" \\\) "))))))

"find /Users/pierrelarochelle/Documents/Source/mixpanel/ -type f -regex \".*\" "

(defun find-file-in-project ()
  "Prompt with a completing list of all files in the project to find one.

The project's scope is defined as the first directory containing
an `.emacs-project' file. You can override this by locally
setting the `ffip-project-root' variable."
  (interactive)
  (let* ((project-files (ffip-project-files))
	 (file (if (functionp 'ido-completing-read)
		   (ido-completing-read "Find file in project: "
					(mapcar 'car project-files))
		 (completing-read "Find file in project: "
				  (mapcar 'car project-files)))))
    (find-file (cdr (assoc file project-files)))))

(provide 'find-file-in-project)
;;; find-file-in-project.el ends here
