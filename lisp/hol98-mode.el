;;; -*- emacs-lisp -*-
;;; to use this mode, you will need to do something along the lines of
;;; the following and have it in your .emacs file:
;;;    (setq hol98-executable "<fullpath to HOL98 executable>")
;;;    (load "<fullpath to this file>")

;;; The fullpath to this file can be just the name of the file, if
;;; your elisp variable load-path includes the directory where it
;;; lives.

(require 'thingatpt)
(require 'cl)

(define-prefix-command 'hol-map)
(define-prefix-command 'hol-d-map)
(make-variable-buffer-local 'hol-buffer-name)
(make-variable-buffer-local 'hol-buffer-ready)
(set-default 'hol-buffer-ready nil)
(set-default 'hol-buffer-name nil)

(set-default 'hol-default-buffer nil)

(defvar hol98-executable 
  "C:/Program Files/Hol/bin/hol"
  "*Path-name for the HOL98 executable.")

(defun hol-set-executable (filename)
  "*Set hol98 executable variable to be NAME."
  (interactive "fHOL98 executable: ")
  (setq hol98-executable filename))

(defvar hol-echo-commands-p nil
  "*Whether or not to echo the text of commands originating elsewhere.")

(defvar hol-generate-locpragma-p t
  "*Whether or not to generate (*#loc row col *) pragmas for HOL.")

(defvar hol-emit-time-elapsed-p nil
  "*Whether or not to print time elapsed messages after causing HOL
evaluations.")

(put 'hol-term 'end-op
     (function (lambda () (skip-chars-forward "^`"))))
(defvar hol-beg-pos nil) ; ugh, global, but easiest this way
(put 'hol-term 'beginning-op
     (function (lambda () (skip-chars-backward "^`") (setq hol-beg-pos (point)))))
(defun hol-term-at-point ()
  (let ((s (thing-at-point 'hol-term)))
    (with-hol-locpragma hol-beg-pos s)))

;;; makes buffer hol aware.  Currently this consists of no more than
;;; altering the syntax table if its major is sml-mode.
(defun make-buffer-hol-ready ()
  (if (eq major-mode 'sml-mode)
      (progn
        (modify-syntax-entry ?` "$")
        (modify-syntax-entry ?\\ "\\"))))

(defun hol-buffer-ok (string)
  "Checks a string to see if it is the name of a good HOL buffer.
In reality this comes down to checking that a buffer-name has a live
process in it."
  (and string (get-buffer-process string)
       (eq 'run
           (process-status
            (get-buffer-process string)))))

(defun ensure-hol-buffer-ok ()
  "Ensures by prompting that a HOL buffer name is OK, and returns it."
  (if (not hol-buffer-ready)
      (progn (make-buffer-hol-ready) (setq hol-buffer-ready t)))
  (if (hol-buffer-ok hol-buffer-name) hol-buffer-name
    (message
     (cond (hol-buffer-name (concat hol-buffer-name " not valid anymore."))
           (t "Please choose a HOL to attach this buffer to.")))
    (sleep-for 1)
    (setq hol-buffer-name (read-buffer "HOL buffer: " hol-default-buffer t))
    (while (not (hol-buffer-ok hol-buffer-name))
      (ding)
      (message "Not a valid HOL process")
      (sleep-for 1)
      (setq hol-buffer-name
            (read-buffer "HOL buffer: " hol-default-buffer t)))
    (setq hol-default-buffer hol-buffer-name)
    hol-buffer-name))


(defun is-a-then (s)
  (and s (or (string-equal s "THEN") (string-equal s "THENL"))))

(defun next-hol-lexeme-terminates-tactic ()
  (skip-syntax-forward " ")
  (or (eobp)
      (char-equal (following-char) ?,)
      ;; (char-equal (following-char) ?=)
      (char-equal (following-char) ?\;)
      (is-a-then (word-at-point))
      (string= (word-at-point) "val")))

(defun previous-hol-lexeme-terminates-tactic ()
  (save-excursion
    (skip-chars-backward " \n\t\r")
    (or (bobp)
        (char-equal (preceding-char) ?,)
        (char-equal (preceding-char) ?=)
        (char-equal (preceding-char) ?\;)
        (and (condition-case nil
                 (progn (backward-char 1) t)
                 (error nil))
             (or (is-a-then (word-at-point))
                 (string= (word-at-point) "val"))))))

;;; returns true and moves forward a sexp if this is possible, returns nil
;;; and stays where it is otherwise
(defun my-forward-sexp ()
  (condition-case nil
      (progn (forward-sexp 1) t)
    (error nil)))
(defun my-backward-sexp()
  (condition-case nil
      (progn (backward-sexp 1) t)
    (error nil)))

(defun skip-hol-tactic-punctuation-forward ()
  (let ((last-point (point)))
    (while (progn (if (is-a-then (word-at-point)) (forward-word 1))
                  (skip-chars-forward ", \n\t\r")
                  (not (= last-point (point))))
      (setq last-point (point)))))

(defun word-before-point ()
  (save-excursion
    (condition-case nil
        (progn (backward-char 1) (word-at-point))
      (error nil))))

(defun skip-hol-tactic-punctuation-backward ()
  (let ((last-point (point)))
    (while (progn (if (is-a-then (word-before-point)) (forward-word -1))
                  (skip-chars-backward ", \n\t")
                  (not (= last-point (point))))
      (setq last-point (point)))))

(defun forward-hol-tactic (n)
  (interactive "p")
  ;; to start you have to get off "tactic" punctuation, i.e. whitespace,
  ;; commas and the words THEN and THENL.
  (let ((count (or n 1)))
    (cond ((> count 0)
           (while (> count 0)
             (let (moved)
               (skip-hol-tactic-punctuation-forward)
               (while (and (not (next-hol-lexeme-terminates-tactic))
                           (my-forward-sexp))
                 (setq moved t))
               (skip-chars-backward " \n\t\r")
               (setq count (- count 1))
               (if (not moved)
                   (error "No more HOL tactics at this level")))))
          ((< count 0)
           (while (< count 0)
             (let (moved)
               (skip-hol-tactic-punctuation-backward)
               (while (and (not (previous-hol-lexeme-terminates-tactic))
                           (my-backward-sexp))
                 (setq moved t))
               (skip-chars-forward " \n\t\r")
               (setq count (+ count 1))
               (if (not moved)
                   (error "No more HOL tactics at this level"))))))))

(defun backward-hol-tactic (n)
  (interactive "p")
  (forward-hol-tactic (if n (- n) -1)))

(defun prim-mark-hol-tactic ()
  (let ((bounds (bounds-of-thing-at-point 'hol-tactic)))
    (if bounds
        (progn
          (goto-char (cdr bounds))
          (push-mark (car bounds) t t)
          (setq mark-active t))
      (error "No tactic at point"))))

(defun mark-hol-tactic ()
  (interactive)
  (let ((initial-point (point)))
    (condition-case nil
        (prim-mark-hol-tactic)
      (error
       ;; otherwise, skip white-space forward to see if this would move us
       ;; onto a tactic.  If so, great, otherwise, go backwards and look for
       ;; one there.  Only if all this fails signal an error.
       (condition-case nil
           (progn
             (skip-chars-forward " \n\t\r")
             (prim-mark-hol-tactic))
         (error
          (condition-case e
              (progn
                (if (skip-chars-backward " \n\t\r")
                    (progn
                      (backward-char 1)
                      (prim-mark-hol-tactic))
                  (prim-mark-hol-tactic)))
            (error
             (goto-char initial-point)
             (signal (car e) (cdr e))))))))))


(defun with-hol-locpragma (pos s)
  (if hol-generate-locpragma-p
      (concat (hol-locpragma-of-position pos) s)
      s))

(defun hol-locpragma-of-position (pos)
  "Convert Elisp position into HOL location pragma.  Not for interactive use."
  (let ((initial-point (point)))
    (goto-char pos)
    (let* ((rowstart (line-beginning-position))
           (row      (+ (count-lines 1 pos)
                      (if (= rowstart pos) 1 0)))
           (col      (+ (current-column) 1)))
      (goto-char initial-point)
      (format " (*#loc %d %d *)" row col))))

(defun send-timed-string-to-hol (string echo-p)
  "Send STRING to HOL (with send-string-to-hol), and emit information about
how long this took."
  (interactive)
  (send-string-to-hol
   "val _ = quietdec := true;
    val hol_mode_time0 = #usr (Timer.checkCPUTimer Globals.hol_clock);
    val _ = quietdec := false")
  (send-string-to-hol string echo-p)
  (send-string-to-hol
       "val _ = let val t = #usr (Timer.checkCPUTimer Globals.hol_clock)
                      val elapsed = Time.-(t, hol_mode_time0)
                in
                      print (\"\\n*** Time taken: \"^
                             Time.toString elapsed^\"s\\n\")
                  end"))


(defun copy-region-as-hol-tactic (start end arg)
  "Send selected region to HOL process as tactic."
  (interactive "r\nP")
  (let* ((region-string (with-hol-locpragma start (buffer-substring start end)))
         (e-string (concat "goalstackLib." (if arg "expandf" "e")))
         (tactic-string
          (format "%s (%s) handle e => Raise e" e-string region-string))
         (sender (if hol-emit-time-elapsed-p
                     'send-timed-string-to-hol
                   'send-string-to-hol)))
    (funcall sender tactic-string hol-echo-commands-p)))

(defun send-string-as-hol-goal (s)
  (let ((goal-string
         (format  "goalstackLib.g `%s` handle e => Raise e" s)))
    (send-raw-string-to-hol goal-string hol-echo-commands-p)
    (send-raw-string-to-hol "goalstackLib.set_backup 100;")))

(defun hol-do-goal (arg)
  "Send term around point to HOL process as goal.
If prefix ARG is true, or if in transient mark mode, region is active and
the region contains no backquotes, then send region instead."
  (interactive "P")
  (let ((txt (condition-case nil
                 (with-hol-locpragma (region-beginning)
                    (buffer-substring (region-beginning) (region-end)))
               (error nil))))
    (if (or (and mark-active transient-mark-mode (= (count ?\` txt) 0))
            arg)
      (send-string-as-hol-goal txt)
    (send-string-as-hol-goal (hol-term-at-point)))))

(defun copy-region-as-hol-definition (start end arg)
  "Send selected region to HOL process as definition/expression."
  (interactive "r\nP")
  (let* ((buffer-string (with-hol-locpragma start (buffer-substring start end)))
         (send-string (if arg
                         (concat "(" buffer-string ") handle e => Raise e")
                       buffer-string))
         (sender (if hol-emit-time-elapsed-p
                     'send-timed-string-to-hol
                   'send-string-to-hol)))
    (funcall sender send-string hol-echo-commands-p)
    (if (> (length send-string) 300)
        (send-string-to-hol
         "val _ = print \"\\n*** Emacs/HOL command completed ***\\n\\n\""))))

(defun hol-name-top-theorem (string arg)
  "Name the top theorem of the goalstackLib.
With prefix argument, drop the goal afterwards."
  (interactive "sName for top theorem: \nP")
  (if (not (string= string ""))
      (send-raw-string-to-hol
       (format "val %s = top_thm()" string)
       hol-echo-commands-p))
  (if arg (send-raw-string-to-hol "goalstackLib.drop()" hol-echo-commands-p)))

(defun remove-sml-comments (end)
  (let (done (start (point)))
    (while (and (not done) (re-search-forward "(\\*\\|\\*)" end t))
        (if (string= (match-string 0) "*)")
            (progn
              (delete-region (- start 2) (point))
              (setq done t))
          ;; found a comment beginning
          (if (not (remove-sml-comments end)) (setq done t))))
      (if (not done) (message "Incomplete comment in region given"))
      done))

(defun remove-hol-term (end-marker)
  (let ((start (point)))
    (if (re-search-forward "`" end-marker t)
        (delete-region (- start 1) (point))
      (error
       "Incomplete HOL quotation in region given; starts >`%s<"
       (buffer-substring (point) (+ (point) 10))))))

(defun remove-dq-hol-term (end-marker)
  (let ((start (point)))
    (if (re-search-forward "``" end-marker t)
        (delete-region (- start 2) (point))
      (error
       "Incomplete (``-quoted) HOL term in region given; starts >``%s<"
       (buffer-substring (point) (+ (point) 10))))))

(defun remove-hol-string (end-marker)
  (let ((start (point)))
    (if (re-search-forward "\n\\|[^\\]?\"" end-marker t)
        (if (string= (match-string 0) "\n")
            (message "String literal terminated by newline - not allowed!")
          (delete-region (- start 1) (point))))))


(defun remove-sml-junk (start end)
  "Removes all sml comments, HOL terms and strings in the given region."
  (interactive "r")
  (let ((m (make-marker)))
    (set-marker m end)
    (save-excursion
      (goto-char start)
      (while (re-search-forward "(\\*\\|`\\|\"" m t)
        (cond ((string= (match-string 0) "(*") (remove-sml-comments m))
              ((string= (match-string 0) "\"") (remove-hol-string m))
              (t ; must be a back-tick
               (if (not (looking-at "`"))
                   (remove-hol-term m)
                 (forward-char 1)
                 (remove-dq-hol-term m)))))
      (set-marker m nil))))

(defun remove-sml-lets-locals
  (start end &optional looking-for-end &optional recursing)
  "Removes all local-in-ends and let-in-ends from a region.  We assume
that the buffer has already had HOL terms, comments and strings removed."
  (interactive "r")
  (let ((m (if (not recursing) (set-marker (make-marker) end) end))
        retval)
    (if (not recursing) (goto-char start))
    (if (re-search-forward "\\blet\\b\\|\\blocal\\b\\|\\bend\\b" m t)
        (let ((declstring (match-string 0)))
          (if (or (string= declstring "let") (string= declstring "local"))
              (and
               (remove-sml-lets-locals (- (point) (length declstring)) m t t)
               (remove-sml-lets-locals start m looking-for-end t)
               (setq retval t))
            ;; found an "end"
            (if (not looking-for-end)
                (message "End without corresponding let/local")
              (delete-region start (point))
              (setq retval t))))
      ;; didn't find anything
      (if looking-for-end
          (message "Let/local without corresponding end")
        (setq retval t)))
    (if (not recursing) (set-marker m nil))
    retval))

(defun word-list-to-regexp (words)
  (mapconcat (lambda (s) (concat "\\b" s "\\b")) words "\\|"))

(setq hol-open-terminator-regexp
      (concat ";\\|"
              (word-list-to-regexp
               '("val" "fun" "in" "infix[lr]?" "open" "local" "type"
                 "datatype" "nonfix" "exception" "end" "structure"))))

(setq sml-struct-id-regexp "[A-Za-z][A-Za-z0-9_]*")

(defun send-string-to-hol (string &optional echoit)
  "Send a string to HOL process."
  (let ((buf (ensure-hol-buffer-ok))
        (hol-ok hol-buffer-ready)
        (tmpbuf (generate-new-buffer "*HOL temporary*"))
        (old-mark-active mark-active))
    (unwind-protect
        (save-excursion
          (set-buffer tmpbuf)
          (setq hol-buffer-name buf) ; version of this variable in tmpbuf
          (setq hol-buffer-ready hol-ok) ; version of this variable in tmpbuf
          (setq case-fold-search nil) ; buffer-local version
          (insert string)
          (goto-char (point-min))
          (remove-sml-junk (point-min) (point-max))
          (goto-char (point-min))
          ;; first thing to do is to search through buffer looking for
          ;; identifiers of form id.id.  When spotted such identifiers need
          ;; to have the first component of the name loaded.
          (while (re-search-forward (concat "\\(" sml-struct-id-regexp
                                            "\\)\\.\\w+")
                                    (point-max) t)
            (hol-load-string (match-string 1)))
          ;; next thing to do is to look for open declarations
          (goto-char (point-min))
          ;; search through buffer for open declarations
          (while (re-search-forward "\\bopen\\b" (point-max) t)
            ;; point now after an open, now search forward to end of
            ;; buffer or a semi-colon, or an infix declaration or a
            ;; val or a fun or another open  (as per the regexp defined just
            ;; before this function definition
            (let ((start (point))
                  (end
                   (save-excursion
                     (if (re-search-forward hol-open-terminator-regexp
                                            (point-max) t)
                         (- (point) (length (match-string 0)))
                       (point-max)))))
              (hol-load-modules-in-region start end)))
          ;; send the string
          (delete-region (point-min) (point-max))
          (insert string)
          (send-buffer-to-hol-maybe-via-file echoit))
      (kill-buffer tmpbuf)) ; kill buffer always
    ;; deactivate-mark will have likely been set by all the editting actions
    ;; in the temporary buffer.  We fix this here, thereby keeping the mark
    ;; active, if it is active.
    (if deactivate-mark (setq deactivate-mark nil))))

(defun interactive-send-string-to-hol (string &optional echoit)
   "Send a string to HOL process."
   (interactive "sString to send to HOL process: \nP")
   (if hol-emit-time-elapsed-p
       (send-timed-string-to-hol string echoit)
     (send-string-to-hol string echoit)))

(defun send-buffer-to-hol-maybe-via-file (&optional echoit)
  "Send the contents of current buffer to HOL, possibly putting it into a
file to \"use\" first."
  (if (< 500 (buffer-size))
          (let ((fname (make-temp-file "hol")))
            ; below, use visit parameter = 1 to stop message in mini-buffer
            (write-region (point-min) (point-max) fname nil 1)
            (send-raw-string-to-hol (format "use \"%s\"" fname)))
    (send-raw-string-to-hol (buffer-string) echoit)))

(defun send-raw-string-to-hol (string &optional echoit)
  "Sends a string in the raw to HOL.  Not for interactive use."
  (let ((buf (ensure-hol-buffer-ok)))
    (if echoit
        (save-excursion
          (set-buffer buf)
          (goto-char (point-max))
          (princ (concat string ";") (get-buffer buf))
          (goto-char (point-max))
          (comint-send-input)
          (hol-recentre))
      (comint-send-string buf (concat string ";\n")))))

(defun hol-backup ()
  "Perform a HOL backup."
  (interactive)
  (send-raw-string-to-hol "goalstackLib.b()" hol-echo-commands-p))

(defun hol-print-goal ()
  "Print the current HOL goal."
  (interactive)
  (send-raw-string-to-hol "goalstackLib.p()" hol-echo-commands-p))

(defun hol-print-all-goals ()
  "Print all the current HOL goals."
  (interactive)
  (send-raw-string-to-hol "goalstackLib.status()" hol-echo-commands-p))

(defun hol-interrupt ()
  "Perform a HOL interrupt."
  (interactive)
  (let ((buf (ensure-hol-buffer-ok)))
    (interrupt-process (get-buffer-process buf))))

(defun hol-recentre ()
  "Display the HOL window in such a way that it displays most text."
  (interactive)
  (ensure-hol-buffer-ok)
  (save-selected-window
    (select-window (get-buffer-window hol-buffer-name t))
    ;; (delete-other-windows)
    (raise-frame)
    (goto-char (point-max))
    (recenter -1)))

(defun hol-rotate (arg)
  "Rotate the goal stack N times.  Once by default."
  (interactive "p")
  (send-raw-string-to-hol (format "goalstackLib.r %d" arg)
                          hol-echo-commands-p))

(defun hol-scroll-up (arg)
  "Scrolls the HOL window."
  (interactive "P")
  (ensure-hol-buffer-ok)
  (save-excursion
    (select-window (get-buffer-window hol-buffer-name t))
    (scroll-up arg)))

(defun hol-scroll-down (arg)
  "Scrolls the HOL window."
  (interactive "P")
  (ensure-hol-buffer-ok)
  (save-excursion
    (select-window (get-buffer-window hol-buffer-name t))
    (scroll-down arg)))

(defun hol-use-file (filename)
  "Gets HOL session to \"use\" a file."
  (interactive "fFile to use: ")
  (send-raw-string-to-hol (concat "use \"" filename "\";")
                          hol-echo-commands-p))

(defun hol-load-string (s)
  "Loads the ML object file NAME.uo; checking that it isn't already loaded."
  (let* ((buf (ensure-hol-buffer-ok))
         (mys (format "%s" s)) ;; gets rid of text properties
         (commandstring
          (concat "val _ = if List.exists (fn s => s = \""
                  mys
                  "\") (Meta.loaded()) then () else "
                  "(print  \"Loading " mys
                  "\\n\"; " "Meta.load \"" mys "\");\n")))
    (comint-send-string buf commandstring)))

(defun hol-load-modules-in-region (start end)
  "Attempts to load all of the words in the region as modules."
  (interactive "rP")
  (save-excursion
    (goto-char start)
    (while (re-search-forward (concat "\\b" sml-struct-id-regexp "\\b") end t)
      (hol-load-string (match-string 0)))))

(defun hol-load-file (arg)
  "Gets HOL session to \"load\" the file at point.
If there is no filename at point, then prompt for file.  If the region
is active (in transient mark mode) and it looks like it might be a
module name or a white-space delimited list of module names, then send
region instead. With prefix ARG prompt for a file-name to load."
  (interactive "P")
  (let* ((wap (word-at-point))
         (txt (condition-case nil
                  (buffer-substring (region-beginning) (region-end))
                (error nil))))
    (cond (arg (hol-load-string (read-string "Library to load: ")))
          ((and mark-active transient-mark-mode
                (string-match (concat "^\\(\\s-*" sml-struct-id-regexp
                                      "\\)+\\s-*$") txt))
           (hol-load-modules-in-region (region-beginning) (region-end)))
          ((and wap (string-match "^\\w+$" wap)) (hol-load-string wap))
          (t (hol-load-string (read-string "Library to load: "))))))


;** hol map keys and function definitions

(defun hol98 (niceness)
  "Runs a HOL98 session in a comint window.
With a numeric prefix argument, runs it niced to that level
or at level 10 with a bare prefix. "
  (interactive "P")
  (let* ((niceval (cond ((null niceness) 0)
                        ((listp niceness) 10)
                        (t (prefix-numeric-value niceness))))
         (holname (format "HOL98(n:%d)" niceval))
         (buf (cond ((> niceval 0)
                     (make-comint holname "nice" nil
                                  (format "-%d" niceval)
                                  hol98-executable))
                    (t (make-comint "HOL98" hol98-executable)))))
    (setq hol-buffer-name (buffer-name buf))
    (switch-to-buffer buf)
    (setq comint-prompt-regexp "^- ")
    (setq hol-buffer-name (buffer-name buf))
    (setq comint-scroll-show-maximum-output t)))

(defun run-program (filename niceness)
  "Runs a PROGRAM in a comint window, with a given (optional) NICENESS."
  (interactive "fProgram to run: \nP")
  (let* ((niceval (cond ((null niceness) 0)
                        ((listp niceness) 10)
                        (t (prefix-numeric-value niceness))))
         (progname (format "%s(n:%d)"
                          (file-name-nondirectory filename)
                          niceval))
         (buf (cond ((> niceval 0)
                     (make-comint progname "nice" nil
                                  (format "-%d" niceval)
                                  (expand-file-name filename)))
                   (t (make-comint progname
                                   (expand-file-name filename)
                                   nil)))))
    (switch-to-buffer buf)))

(defun hol-toggle-var (s)
  "Toggles the boolean variable STRING."
  (message (concat "Toggling " s))
  (send-raw-string-to-hol
   (format (concat "val _ = (%s := not (!%s);"
                   "print (\"*** %s now \" ^"
                   "Bool.toString (!%s)^\" ***\\n\"))")
           s s s s)))

(defun hol-toggle-trace (s &optional arg)
  "Toggles the trace variable STRING between zero and non-zero.  With prefix
argument N, sets the trace to that value in particular."
  (interactive "sTrace name: \nP")
  (if (null arg)
      (progn
        (message (concat "Toggling " s))
        (send-raw-string-to-hol
         (format "val _ = let val nm = \"%s\"
                      fun findfn r = #name r = nm
                      val old =
                            #trace_level (valOf (List.find findfn (traces())))
                  in
                      print (\"** \"^nm^\" trace now \");
                      if 0 < old then (set_trace nm 0; print \"off\\n\")
                      else (set_trace nm 1; print \"on\\n\")
                  end handle Option =>
                        print \"** No such trace var: \\\"%s\\\"\\n\""
                 s s)))
    (let ((n (prefix-numeric-value arg)))
      (message (format "Setting %s to %d" s n))
      (send-raw-string-to-hol
       (format "val _ = (set_trace \"%s\" %d; print \"** %s trace now %d\\n\")
                        handle HOL_ERR _ =>
                           print \"** No such trace var: \\\"%s\\\"\\n\""
               s n s n s)))))

(defun hol-toggle-goalstack-fvs ()
  "Toggles the trace \"goalstack fvs\"."
  (interactive)
  (hol-toggle-trace "goalstack fvs"))

(defun hol-toggle-simplifier-trace (arg)
  "Toggles the trace \"simplifier\".  With ARG sets trace to this value."
  (interactive "P")
  (hol-toggle-trace "simplifier" arg))

(defun hol-toggle-show-types (arg)
  "Toggles the global show_types variable. With prefix ARG toggles the related
variable show_types_verbosely instead."
  (interactive "P")
  (if arg
      (hol-toggle-var "Globals.show_types_verbosely")
    (hol-toggle-var "Globals.show_types")))

(defun hol-toggle-show-numeral-types()
  "Toggles the global show_numeral_types variable."
  (interactive)
  (hol-toggle-var "Globals.show_numeral_types"))

(defun hol-toggle-show-assums()
  "Toggles the global show_assums variable."
  (interactive)
  (hol-toggle-var "Globals.show_assums"))

(defun hol-toggle-quietdec ()
  "Toggles the ML \"meta\" variable, quietdec."
  (interactive)
  (hol-toggle-var "Meta.quietdec"))

(defun hol-toggle-show-times()
  "Toggles the elisp variable 'hol-emit-time-elapsed-p."
  (interactive)
  (setq hol-emit-time-elapsed-p (not hol-emit-time-elapsed-p))
  (message (if hol-emit-time-elapsed-p "Elapsed times WILL be displayed"
             "Elapsed times WON'T be displayed")))


(defun set-hol-executable (filename)
  "Sets the HOL executable variable to be equal to FILENAME."
  (interactive "fHOL executable: ")
  (setq hol98-executable filename))

(defun hol-restart-goal ()
  "Restarts the current goal."
  (interactive)
  (send-raw-string-to-hol "goalstackLib.restart()" hol-echo-commands-p))

(defun hol-drop-goal ()
  "Drops the current goal."
  (interactive)
  (send-raw-string-to-hol "goalstackLib.drop()" hol-echo-commands-p))

(defun hol-open-string (prefixp)
  "Opens HOL modules, prompting for the name of the module to load.
With prefix ARG, toggles quietdec variable before and after opening,
potentially saving a great deal of time as tediously large modules are
printed out.  (That's assuming that quietdec is false to start with.)"
  (interactive "P")
  (let* ((prompt0 "Name of module to (load and) open")
         (prompt (concat prompt0 (if prefixp " (toggling quietness)") ": "))
         (module-name (read-string prompt)))
    (hol-load-string module-name)
    (if prefixp (hol-toggle-quietdec))
    (send-raw-string-to-hol (concat "open " module-name) hol-echo-commands-p)
    (if prefixp (hol-toggle-quietdec))))

(defun hol-db-match (tm)
  "Does a DB.match [] on the given TERM (given as a string, without quotes)."
  (interactive "sTerm to match on: ")
  (send-raw-string-to-hol (format "DB.match [] (Term`%s`)" tm)
                          hol-echo-commands-p))

(defun hol-drop-all-goals ()
  "Drops all HOL goals from the current proofs object."
  (interactive)
  (send-raw-string-to-hol
   (concat "goalstackLib.dropn (case goalstackLib.status() of "
           "GoalstackPure.PRFS l => List.length l)")))

(defun hol-subgoal-tactic ()
  "Sends term at point (delimited by backquote characters) as a
subgoal.  Will usually create at least two sub-goals; one will be the
term just sent, and the others will be the term sent STRIP_ASSUME'd
onto the assumption list of the old goal.  (Loads the Q module if not
already loaded.)"
  (interactive)
  (send-string-to-hol
   (format "goalstackLib.e (Q.SUBGOAL_THEN `%s` STRIP_ASSUME_TAC)"
           (hol-term-at-point))))

;; (defun hol-return-key ()
;;   "Run comint-send-input, but only if both: the user is editting the
;; last command in the buffer, and that command ends with a semicolon.
;; Otherwise, insert a newline at point."
;;   (interactive)
;;   (let ((comand-finished
;;          (let ((process (get-buffer-process (current-buffer))))
;;            (and (not (null process))
;;                 (let ((pmarkpos (marker-position
;;                                  (process-mark process))))
;;                   (and (< (point) pmarkpos)
;;                        (string-match ";[ \t\n\r]*$"
;;                                      (buffer-substring pmarkpos
;;                                                        (point-max)))))))))
;;     (if command-finished
;;         (progn
;;           (goto-char (point-max))
;;           (comint-send-input))
;;       (insert "\n"))))

;; (define-key comint-mode-map "\r" 'hol-return-key)


(define-key global-map "\M-h" 'hol-map)

(define-key hol-map "\C-a" 'hol-toggle-show-assums)
(define-key hol-map "\C-c" 'hol-interrupt)
(define-key hol-map "\C-f" 'hol-toggle-goalstack-fvs)
(define-key hol-map "\C-l" 'hol-recentre)
(define-key hol-map "\C-n" 'hol-toggle-show-numeral-types)
(define-key hol-map "\C-q" 'hol-toggle-quietdec)
(define-key hol-map "\C-s" 'hol-toggle-simplifier-trace)
(define-key hol-map "\C-t" 'hol-toggle-show-types)
(define-key hol-map "\C-v" 'hol-scroll-up)
(define-key hol-map "\M-f" 'forward-hol-tactic)
(define-key hol-map "\M-b" 'backward-hol-tactic)
(define-key hol-map "\M-r" 'copy-region-as-hol-definition)
(define-key hol-map "\M-t" 'hol-toggle-show-times)
(define-key hol-map "\M-s" 'hol-subgoal-tactic)
(define-key hol-map "\M-v" 'hol-scroll-down)
(define-key hol-map "b"    'hol-backup)
(define-key hol-map "d"    'hol-drop-goal)
(define-key hol-map "D"    'hol-drop-all-goals)
(define-key hol-map "e"    'copy-region-as-hol-tactic)
(define-key hol-map "g"    'hol-do-goal)
(define-key hol-map "h"    'hol98)
(define-key hol-map "l"    'hol-load-file)
(define-key hol-map "m"    'hol-db-match)
(define-key hol-map "n"    'hol-name-top-theorem)
(define-key hol-map "o"    'hol-open-string)
(define-key hol-map "p"    'hol-print-goal)
(define-key hol-map "P"    'hol-print-all-goals)
(define-key hol-map "r"    'hol-rotate)
(define-key hol-map "R"    'hol-restart-goal)
(define-key hol-map "t"    'mark-hol-tactic)
(define-key hol-map "s"    'interactive-send-string-to-hol)
(define-key hol-map "u"    'hol-use-file)
