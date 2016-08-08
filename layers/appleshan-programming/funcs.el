;;; funcs.el --- appleshan-programming Layer functions File for Spacemacs
;;
;; Copyright (c) 2016-2020 Apple Shan
;;
;; Author: Apple Shan <apple.shan@gmail.com>
;; URL: https://github.com/appleshan/my-spacemacs-config
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;; 让 emacs 自动給 script 加上可执行权限
;; 保存时,检查文件的第一行是否包含#!,若包含则给文件添加执行权限
(defun appleshan-programming/maybe-make-executable ()
  "Maybe make file executable unless it is a backup file."
  (unless (backup-file-name-p buffer-file-name)
    (executable-make-buffer-file-executable-if-script-p)))

(add-hook 'after-save-hook 'appleshan-programming/maybe-make-executable)

;; add auto format paste code
(dolist (command '(yank yank-pop))
  (eval
   `(defadvice ,command (after indent-region activate)
      (and (not current-prefix-arg)
           (member major-mode
                   '(emacs-lisp-mode
                     lisp-mode
                     scheme-mode
                     python-mode
                     js-mode))
           (let ((mark-even-if-inactive transient-mark-mode))
             (indent-region (region-beginning) (region-end) nil))))))

(defun appleshan-programming/vcs-project-root ()
  "Return the project root for current buffer."
  (let ((directory default-directory))
    (or (locate-dominating-file directory ".git")
        (locate-dominating-file directory ".svn")
        (locate-dominating-file directory ".hg"))))

(defun appleshan-programming/goto-match-paren (arg)
  "Go to the matching  if on (){}[], similar to vi style of % "
  (interactive "p")
  ;; first, check for "outside of bracket" positions expected by forward-sexp, etc
  (cond ((looking-at "[\[\(\{]") (evil-jump-item))
        ((looking-back "[\]\)\}]" 1) (evil-jump-item))
        ;; now, try to succeed from inside of a bracket
        ((looking-at "[\]\)\}]") (forward-char) (evil-jump-item))
        ((looking-back "[\[\(\{]" 1) (backward-char) (evil-jump-item))
        (t nil)))

(defun appleshan-programming/hidden-dos-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(defun appleshan-programming/remove-dos-eol ()
  "Replace DOS eolns CR LF with Unix eolns CR"
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\r" nil t) (replace-match "")))

;;{{ compile
;; This gives a regular `compile-command' prompt.
(define-key prog-mode-map [C-f9] #'compile)
;; This just compiles immediately.
(define-key prog-mode-map [f9] #'endless/compile-please)

;; I'm not scared of saving everything.
(setq compilation-ask-about-save nil)
;; Stop on the first error.
(setq compilation-scroll-output 'next-error)
;; Don't stop on info or warnings.
(setq compilation-skip-threshold 2)

(defcustom endless/compile-window-size 105
  "Width given to the non-compilation window."
  :type 'integer
  :group 'endless)

(defun endless/compile-please (comint)
  "Compile without confirmation.
With a prefix argument, use comint-mode."
  (interactive "P")
  ;; Do the command without a prompt.
  (save-window-excursion
    (compile (eval compile-command) (and comint t)))
  ;; Create a compile window of the desired width.
  (pop-to-buffer (get-buffer "*compilation*"))
  (enlarge-window
   (- (frame-width)
      endless/compile-window-size
      (window-width))
   'horizontal))
;;}}

(defmacro appleshan/toggle-company-backends (backend)
  "Push or delete the backend to company-backends"
  (let ((funsymbol (intern (format "appleshan/company-toggle-%S" backend))))
    `(defun ,funsymbol ()
       (interactive)
       (if (eq (car company-backends) ',backend)
           (setq-local company-backends (delete ',backend company-backends))
         (push ',backend company-backends)))))

;;{{ Better Comments or tooling as a time sink
;; @See http://cestlaz.github.io/posts/better-comments/
(make-face 'font-lock-comment-important)
(set-face-foreground 'font-lock-comment-important "#00ff00")

(make-face 'font-lock-comment-todo)
(set-face-foreground 'font-lock-comment-todo "#ff0000")

(make-face 'font-lock-comment-strike)
(set-face-attribute 'font-lock-comment-strike
        nil :strike-through t)

(defun add-custom-keyw()
  "adds a few special keywords"
  (font-lock-add-keywords 
   nil
   '(("cx \\(.+\\)" 1 'font-lock-comment-strike prepend)
     ("ct \\(.+\\)" 1 'font-lock-comment-todo prepend)
     ("ci \\(.+\\)" 1 'font-lock-comment-important prepend)
     )))

(add-hook 'prog-mode-hook #'add-custom-keyw)
;;}}

;;{{ my fix for tab indent
(defun appleshan/indent-region(numSpaces)
  (progn
    ; default to start and end of current line
    (setq regionStart (line-beginning-position))
    (setq regionEnd (line-end-position))

    ; if there's a selection, use that instead of the current line
    (when (use-region-p)
      (setq regionStart (region-beginning))
      (setq regionEnd (region-end))
      )

    (save-excursion                          ; restore the position afterwards
      (goto-char regionStart)                ; go to the start of region
      (setq start (line-beginning-position)) ; save the start of the line
      (goto-char regionEnd)                  ; go to the end of region
      (setq end (line-end-position))         ; save the end of the line

      (indent-rigidly start end numSpaces) ; indent between start and end
      (setq deactivate-mark nil)           ; restore the selected region
      )
  ))


(defun appleshan/tab-region (N)
  (interactive "p")
  (if (use-region-p)
      (appleshan/indent-region 4) ; region was selected, call indent-region
    (insert "    ")                   ; else insert four spaces as expected
    ))

(defun appleshan/untab-region (N)
  (interactive "p")
  (appleshan/indent-region -4))

(defun appleshan/hack-tab-key ()
  (interactive)
  (local-set-key (kbd "<tab>") 'appleshan/tab-region)
  (local-set-key (kbd "<S-tab>") 'appleshan/untab-region)
  )

(add-hook 'prog-mode-hook 'appleshan/hack-tab-key)
;;}}

(with-eval-after-load 'ivy
  (defun my-unwind-git-timemachine ()
    (if (not (eq last-command-event 13))
      (git-timemachine-quit)))

  ;; http://blog.binchen.org/posts/new-git-timemachine-ui-based-on-ivy-mode.html
  (defun my-git-timemachine-show-selected-revision ()
    "Show last (current) revision of file."
    (interactive)
    (let (collection)
      (setq collection
            (mapcar (lambda (rev)
                      ;; re-shape list for the ivy-read
                      (cons (concat (substring (nth 0 rev) 0 7) "|" (nth 5 rev) "|" (nth 6 rev)) rev))
                    (git-timemachine--revisions)))
      (ivy-read "commits:"
                collection
                :unwind #'my-unwind-git-timemachine
                :action (lambda (rev)
                          (git-timemachine-show-revision (cdr rev))))))

  (defun my-git-timemachine ()
    "Open git snapshot with the selected version.  Based on ivy-mode."
    (interactive)
    (unless (featurep 'git-timemachine)
      (require 'git-timemachine))
    (git-timemachine--start #'my-git-timemachine-show-selected-revision))
)

;; Local Variables:
;; coding: utf-8
;; no-byte-compile: nil
;; End:

;;; funcs.el ends here