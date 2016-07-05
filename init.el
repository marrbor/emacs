;;; package --- init
;;; Commentary:
;;; Code:

;; melpa
(when (>= emacs-major-version 24)
  (require 'package)
  (add-to-list
   'package-archives
   '("melpa" . "http://melpa.org/packages/")
   t)
;  (add-to-list
;   'package-archives
;   '("marmalade" . "http://marmalade-repo.org/packages/")
;   )
  (package-initialize))


;; 環境変数をロードし、PATH については「exec-path」に入れる
;; package-initialize より後で行うこと。
;; https://github.com/purcell/exec-path-from-shell
(when (not (equal system-type 'windows-nt))
  (progn
    (exec-path-from-shell-initialize)
    (exec-path-from-shell-copy-env "GOROOT")
    (exec-path-from-shell-copy-env "GOPATH")
    (exec-path-from-shell-copy-env "JAVA_HOME")
    ))

;;; eshell に PATH を渡す
(defvar eshell-path-env (getenv "PATH"))




;;; init.el を起動後にバイトコンパイルする
(add-hook 'after-init-hook
	  (lambda ()
	    (if (file-newer-than-file-p "~/.emacs.d/init.el" "~/.emacs.d/init.elc")
		(progn
		  (require 'bytecomp)
		  (displaying-byte-compile-warnings
		   (unless (byte-compile-file "~/.emacs.d/init.el")
		     (signal nil nil)))))))

;;; init.el を終了時にバイトコンパイルする
(add-hook 'kill-emacs-hook
	  (lambda ()
	    (if (file-newer-than-file-p "~/.emacs.d/init.el" "~/.emacs.d/init.elc")
		(progn
		  (require 'bytecomp)
		  (displaying-byte-compile-warnings
		   (unless (byte-compile-file "~/.emacs.d/init.el")
		     (signal nil nil)))))))


;;Key bind
(global-set-key "\C-h" 'backward-delete-char)
(global-set-key "\C-t" 'scroll-down)
(global-set-key "\C-s" 'isearch-forward-regexp)
(global-set-key "\C-r" 'isearch-backward-regexp)
(global-set-key "\C-co" 'revert-buffer)
(global-set-key "\M-%" 'query-replace-regexp)
(global-set-key "\M-?" 'help-for-help)
(global-set-key "\M-M" 'compile)
(global-set-key "\M-N" 'next-error)
(global-set-key "\C-ce" 'eval-current-buffer)
(global-set-key "\C-cj" 'goto-line)
(global-unset-key "\C-]")
(global-unset-key "\C-z")
(global-set-key "\C-xm" 'browse-url-at-point)
(global-set-key "\C-q" 'indent-region)
(global-set-key "\C-xj" 'skk-mode)

;;; Font
(if window-system (cons
		   (set-face-attribute 'default nil
				       :family "Ricty Discord"
				       :height 120)
		   (set-fontset-font (frame-parameter nil 'font)
				     'japanese-jisx0208
				     (cons "Ricty Discord" "iso10646-1"))
		   (set-fontset-font (frame-parameter nil 'font)
				     'japanese-jisx0212
				     (cons "Ricty Discord" "iso10646-1"))
		   (set-fontset-font (frame-parameter nil 'font)
				     'katakana-jisx0201
				     (cons "Ricty Discord" "iso10646-1"))))

;;; 長いリストの表示を省略する(数字:MAXの数(default:12)、nil:省略しない)
(setq eval-expression-print-length nil)

;;使用言語
(set-language-environment "Japanese")

(set-default-coding-systems 'utf-8-unix)
;; ターミナルモードで使用する場合の表示用文字コードを設定します。
(set-terminal-coding-system 'utf-8-unix)
;; ターミナルモードで使用する場合のキー入力文字コードを設定します。
(set-keyboard-coding-system 'utf-8-unix)
(setq network-coding-system-alist '(("nntp" . (junet-unix . junet-unix))
                                    (110 . (no-conversion . no-conversion))
                                    (25 . (no-conversion . no-conversion))))

;;;
(setq debug-on-error t)

;;;
;; font-lock
(global-font-lock-mode t)
(setq font-lock-support-mode 'jit-lock-mode)
; added by masahide 2003/4/28 font-lock-mode-internal cannot loaded when update emacs CVS
(autoload 'font-lock-mode-internal "font-lock" "font-lock-mode-internal" t)
(setq auto-save-list-file-prefix "~/.emacs.d/auto-save-list/.saves-")
(setq temporary-file-directory "~/.emacs.d/tmp")


;;; 時計表示
(setq display-time-day-and-date t)
(display-time)

;;;ruby
(setq auto-mode-alist (cons '("\\.rb$" . ruby-mode)
			    auto-mode-alist))

(autoload 'ruby-mode "ruby-mode" "RUBY mode" t)

;;;
;;; ModeLine Color
;;; ラインナンバーモード:オン(nil = off)
;;; カラム数表示
(setq line-number-mode t)
(column-number-mode 1)

;;;
;;; 対応括弧のハイライト化
;;;
(show-paren-mode 1)

;;; 新規行自動作成:オフ
(setq next-line-add-newlines nil)

;;; バックアップファイル作成:オフ
(setq make-backup-files nil)

;;; 行頭でのC-kは一撃で１行削除
(setq kill-whole-line t)

;;;
;;; ヘルプ高速化
;;;
(autoload 'fast-apropos "fast-apropos" nil t)
(autoload 'fast-command-apropos "fast-apropos" nil t)
(autoload 'super-apropos "fast-apropos" nil t)
(define-key help-map "a" 'fast-command-apropos)

;;;
;;;  実行コマンドのキーバインディングを通知
;;;
(load "execcmd" t)


;;;
;;; C-x T で時刻を埋め込み
;;;
(define-key ctl-x-map "T" 'insert-current-time-string)
(defun insert-current-time-string ()
  "Insert current time string at point."
  (interactive)
  (insert (format-time-string "%Y/%m/%d %T %z")))


(put 'set-goal-column 'disabled nil)
(put 'upcase-region 'disabled nil)

;;; shell-mode で ^M を出さなくする．
(add-hook 'comint-output-filter-functions 'shell-strip-ctrl-m nil t)

;; 長い文章の折り返しで物理的に次の行に移動
(global-set-key "\C-p" 'previous-window-line)
(global-set-key "\C-n" 'next-window-line)
(global-set-key [up] 'previous-window-line)
(global-set-key [down] 'next-window-line)
(defun previous-window-line (n)
  "N as lines have to move."
  (interactive "p")
  (let ((cur-col
	 (- (current-column)
	    (save-excursion (vertical-motion 0) (current-column)))))
    (vertical-motion (- n))
    (move-to-column (+ (current-column) cur-col)))
  (run-hooks 'auto-line-hook))
(defun next-window-line (n)
  "N as lines have to move."
  (interactive "p")
  (let ((cur-col
	 (- (current-column)
	    (save-excursion (vertical-motion 0) (current-column)))))
    (vertical-motion n)
    (move-to-column (+ (current-column) cur-col)))
  (run-hooks 'auto-line-hook))


;; Auto +x
(add-hook
 'after-save-hook
 '(lambda ()
    (save-restriction
      (widen)
      (if (or
	   (string= "#!" (buffer-substring 1 (min 3 (point-max))))
	   (string-match ".cgi$" (buffer-file-name)))
	  (let ((name (buffer-file-name)))
	    (or (char-equal ?. (string-to-char (file-name-nondirectory name)))
		(let ((mode (file-modes name)))
		  (set-file-modes name (logior mode (logand (/ mode 4) 73)))
		  (message (concat "Wrote " name " (+x)"))))
	    )))))

;; バッファを切り替えるのに C-x e で electric-buffer-list を使う。
(global-set-key "\C-xe" 'electric-buffer-list)

;;;気軽にバイトコンパイル。
(defun kasu-byte-compile-this-file ()
  "Compile current-buffer-file of Lisp into a file of byte code."
  (interactive)
  (byte-compile-file buffer-file-name t))
(global-set-key "\C-x!" 'kasu-byte-compile-this-file)

;;;高速バッファ切替
(fset 'previous-buffer 'bury-buffer)


;;;C-hv とかファイル名補完時のウィンドウを自動的にリサイズする。
(temp-buffer-resize-mode t)

;;;検索とかリージョンを色付きに。
(setq transient-mark-mode t)
(setq search-highlight t)
(setq query-replace-highlight t)

;;;強力な補完
;(partial-completion-mode t)

;;; 以下のように .emacs に記入しておくと C-x %で対応する括弧に簡単に飛べるようになります．
;;; http://www.geocities.co.jp/Bookend-Soseki/1554/soft/meadow_10.html
(progn
  (defvar com-point nil
    "Remember com point as a marker. \(buffer specific\)")
  (set-default 'com-point (make-marker))
  (defun getcom (arg)
    "Get com part of prefix-argument ARG."
    (cond ((null arg) nil)
	  ((consp arg) (cdr arg))
	  (t nil)))
  (defun paren-match (arg)
    "Go to the matching parenthesis."
    (interactive "P")
    (let ((com (getcom arg)))
      (if (numberp arg)
	  (if (or (> arg 99) (< arg 1))
	      (error "Prefix must be between 1 and 99.")
	    (goto-char
	     (if (> (point-max) 80000)
		 (* (/ (point-max) 100) arg)
	       (/ (* (point-max) arg) 100)))
	    (back-to-indentation))
	(cond ((looking-at "[\(\[{]")
	       (if com (move-marker com-point (point)))
	       (forward-sexp 1)
	       (if com
		   (paren-match com)
		 (backward-char)))
	      ((looking-at "[])}]")
	       (forward-char)
	       (if com (move-marker com-point (point)))
	       (backward-sexp 1)
	       (if com (paren-match com)))
	      (t (error ""))))))
  (define-key ctl-x-map "%" 'paren-match))

;;; ediffを別フレームにしない
(defvar ediff-window-setup-function 'ediff-setup-windows-plain)

;;; http://pc.2ch.net/test/read.cgi/unix/1058495083/762
;;; cwarn.el … C/C++で怪しい部分をハイライトしてくれる。
(setq global-cwarn-mode t)

;;; tab幅
(setq-default default-tab-width 8)
(setq-default indent-tabs-mode nil)

(add-hook 'text-mode-hook
          (lambda ()
			(define-key text-mode-map "\M-t" '
			  (lambda() (interactive)(insert (format-time-string "::%Y-%m-%d(%a) %H:%M" (current-time)))))))

;;--------------------------------------------------------------------------
;; ins-ref.el (Version 1.02)
;;--------------------------------------------------------------------------
;; 説明:
;;   マークされた所からカーソルのある行までの間の行の先頭に文字列を
;;   いれる emacs-lisp プログラムです。メールや GUNS の引用記号を
;;   挿入したり、lisp や C++ のコメントアウトするのに使用できます。 
;;
;; 「.emacs」の設定:
;;    (setq load-path (cons ("プログラムの置場所") load-path))
;;    (load "ins-ref")
;; 
;; 使い方:
;;    [Ctrl]+[c][j] : マークをつけたところから現在のカーソル位置までの
;;                    行の先頭に引用記号(デフォルトは" | ")を挿入します。
;;    [Ctrl]+[c][i] : マークをつけたところから現在のカーソル位置までの
;;                    行の先頭に指定の文字列を挿入します。
;;    [Ctrl]+[c][d] : マークをつけたところから現在のカーソル位置までの
;;                    矩形領域を削除します。
;;    ※ [Ctrl]+[c][j] はコントロールキーを押しながら c を
;;       押したあとに、j のみを押すことを示しています。
;; 
;; 例:
;;   [挿入]
;;     +---------------+    「G」のところで           +---------------+ 
;;     |ABCDEF         |    [Ctrl]+[space] を         |ABCDEF         |
;;     |GHIJKL         |    押してマークをつける      |// GHIJKL      |
;;     |MNOPQR         | → カーソルを「S」に      → |// MNOPQR      |
;;     |STUVWX         |    移動し[Ctrl]+[c][i]を     |// STUVWX      |
;;     |YZ             |    押し「// 」を入力する。   |YZ             |
;;     +---------------+    GUIの環境では、「G」      +---------------+
;;                          から「S」までをドラッグ
;;                          したあとに[Ctrl]+[c][i]
;;                          でも可能です。
;;
;;   [削除]
;;     +---------------+    「G」の行の行頭で         +---------------+ 
;;     |ABCDEF         |    [Ctrl]+[space] を         |ABCDEF         |
;;     |// GHIJKL      |    押してマークをつける      |GHIJKL         |
;;     |// MNOPQR      | → カーソルを「S」に      → |MNOPQR         |
;;     |// STUVWX      |    移動し[Ctrl]+[c][d]を     |STUVWX         |
;;     |YZ             |    押す。                    |YZ             |
;;     +---------------+    GUIの環境では、「G」の    +---------------+
;;                          行頭の「/」から「S」
;;                          までをドラッグしたあとに
;;                          [Ctrl]+[c][d]でも可能です。
;;
;;--------------------------------------------------------------------------
;;                             Copyright (C) 1994-2001 TSURUTA Mitsutoshi
;;--------------------------------------------------------------------------

;;  処理の本体
(defun ins-ref-str (ref-str)
  "REF-STR: 引用記号。行の頭に、引用記号をいれる."
  (interactive "sinsert string : ")
  (if (> (mark) (point)) (exchange-point-and-mark))
  (save-excursion
    (goto-char (mark))
    (beginning-of-line)
    (defvar ins-ref-top_pos)
    (setq ins-ref-top_pos (point)))
  (beginning-of-line)
  (while (< ins-ref-top_pos (point))
    (insert ref-str)
    (forward-line -1)
    (beginning-of-line))
  (insert ref-str)
)

;;  何の文字列を入れるかを問い合わせないで実行する。
;;        (ins-ref-str ....) の 文字列部分を書き換えると
;;        その文字列を挿入するようになります。
(defun ins-ref ()
  "何の文字列を入れるかを問い合わせないで行の頭に、引用記号をいれる."
  (interactive)
  (ins-ref-str "  | ")
)

;; 矩形削除
(defun del-ref ()
  "矩形領域を削除する."
  (interactive)
  (kill-rectangle (mark) (point))
)

;;  キーの割り当て
;;(global-set-key "\C-cj" 'ins-ref)
(global-set-key "\C-ci" 'ins-ref-str)
(global-set-key "\C-cd" 'del-ref)

;;; define ins-ref ends here.

(put 'narrow-to-region 'disabled nil)

;;;w3m
;(require 'w3m-load)
(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)

;;; JavaScript
(add-hook 'js-mode-hook
 	  (lambda () (flymake-mode t)))

;;;groovy
(autoload 'groovy-mode "groovy-mode" "Major mode for editing Groovy code." t)
(add-to-list 'auto-mode-alist '("\.groovy$" . groovy-mode))
(add-to-list 'auto-mode-alist '("\.gradle$" . groovy-mode))
(add-to-list 'interpreter-mode-alist '("\.groovy$" . groovy-mode))
(add-to-list 'interpreter-mode-alist '("\.gradle$" . groovy-mode))
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))

(add-hook 'groovy-mode-hook
          '(lambda ()
             (require 'groovy-electric)
             (groovy-electric-mode)))

;;; java
(add-hook 'java-mode-hook
	  (lambda ()
	    (setq indent-tabs-mode nil)))
;	    (setq c-basic-offset 4)))

;;; python
(add-to-list 'auto-mode-alist '("\.wsgi$" . python-mode))


;;; C#
(autoload 'csharp-mode "csharp-mode" "Major mode for editing C# code." t)
(add-to-list 'auto-mode-alist '("\.cs$" . csharp-mode))
(add-hook 'csharp-mode-hook
          '(lambda ()
             (setq comment-column 40)
             (setq c-basic-offset 4)
             (c-set-offset 'substatement-open 0)
             (c-set-offset 'case-label '+)
             (c-set-offset 'arglist-intro '+)
             (c-set-offset 'arglist-closen 0)))


;;; NSIS
(autoload 'nsis-mode "nsis-mode" "nsi editing mode." t)
(add-to-list 'auto-mode-alist '("\.ns[ih]$" . nsis-mode))

;;; Git
(require 'magit)
;(require 'git)
;(require 'git-blame)

;;; Markdown
(autoload 'markdown-mode "markdown-mode"
   "Major mode for editing Markdown files" t)
;(add-to-list 'auto-mode-alist '("\\.text\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;;; HTMLIZE
(autoload 'htmlize-buffer "htmlize" "Convert BUFFER to HTML, preserving colors and decorations." t)
(autoload 'htmlize-region "htmlize" "Convert the region to HTML, preserving colors and decorations." t)
(autoload 'htmlize-file "htmlize" "Load FILE, fontify it, convert it to HTML, and save the result." t)

;;; org-mode
;(setq org-export-latex-classes nil)
;(add-to-list 'org-export-latex-classes
;	     '("report"
;	       "
;	       \\documentclass{jsarticle}
;	       \\usepackage[dvipdfmx]{graphicx}
;	       \\usepackage[utf8]{inputenc}
;	       \\usepackage[T1]{fontenc}
;	       "
;	       ("\\chapter{%s}" . "\\chapter*{%s}")
;	       ("\\section{%s}" . "\\section*{%s}")
;	       ("\\subsection{%s}" . "\\subsection*{%s}")
;	       ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
;	       ("\\paragraph{%s}" . "\\paragraph*{%s}")
;	       ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

;(add-to-list 'org-export-latex-classes
;	     '("minireport"
;	       "
;	       \\documentclass{jsarticle}
;	       \\usepackage[dvipdfmx]{graphicx}
;	       \\usepackage[utf8]{inputenc}
;	       \\usepackage[T1]{fontenc}
;	       "
;	       ("\\subsection{%s}" . "\\subsection*{%s}")
;	       ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
;	       ("\\paragraph{%s}" . "\\paragraph*{%s}")
;	       ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

;;; org-mode ditaa
(defvar org-ditaa-jar-path (expand-file-name "~/.emacs.d/libs/ditaa/jditaa.jar"))

(add-hook 'picture-mode-hook 'picture-mode-init)
(autoload 'picture-mode-init "picture-init")

;;; C-c C-c inside #+BEGIN_SRC .. #+END_SRC
(org-babel-do-load-languages
 'org-babel-load-languages
 '((C . t)
   (R . t)
   (asymptote . t)
   (awk . t)
   (calc . t)
   (clojure . t)
   (comint . t)
   (css . t)
   (ditaa . t)
   (dot . t)
   (emacs-lisp . t)
   (eval . t)
   (exp . t)
   (fortran . t)
   (gnuplot . t)
   (haskell . t)
   (io . t)
   (java . t)
   (js . t)
   (keys . t)
   (latex . t)
   (ledger . t)
   (lilypond . t)
   (lisp . t)
   (lob . t)
   (matlab . t)
   (maxima . t)
   (mscgen . t)
   (ocaml . t)
   (octave . t)
   (org . t)
   (perl . t)
   (picolisp . t)
   (plantuml . t)
   (python . t)
   (ref . t)
   (ruby . t)
   (sass . t)
   (scala . t)
   (scheme . t)
   (screen . t)
   (sh . t)
   (shen . t)
   (sql . t)
   (sqlite . t)
   (table . t)
   (tangle . t)))


;;; BEGIN_SRC ブロックの評価時、いちいち yes-no-p させない
;;; その代わり危険なコードには :eval never をつける必要がある。
(defvar org-confirm-babel-evaluate nil)

;;; BEGIN_SRC ブロックの評価時、ditaa か dot なら yes-no-p させない
;(defun my-org-confirm-babel-evaluate (lang body)
;  (not (or (string= lang "ditaa") (string= lang "dot"))))
;(setq org-confirm-babel-evaluate 'my-org-confirm-babel-evaluate)

;; active Org-babel languages
(org-babel-do-load-languages
 'org-babel-load-languages
 '(;; other Babel languages
   (plantuml . t)))

(defvar org-plantuml-jar-path
      (expand-file-name "~/.emacs.d/libs/plantUML/plantuml.jar"))

;;; SKK
;; SKK の設定は、~/.skk の方が優先されます。
;; 下記の設定は、特殊な事情があるため ~/.skk ではうまく機能しない設定を
;; 集めていますので、下記以外は ~/.skk で設定することをお勧めします。
;; 「カタカナ/ひらがな」キーで SKK を起動する
(global-set-key [hiragana-katakana] 'skk-mode)

;; ~/.skk にいっぱい設定を書いているのでバイトコンパイルしたい
(defvar skk-byte-compile-init-file t)
;; 注) 異なる種類の Emacsen を使っている場合は nil にします

;; SKK を Emacs の input method として使用する
;;   `toggle-input-method' (C-\) で DDSKK が起動します
(setq default-input-method
      "japanese-skk"			; (skk-mode 1)
;;    "japanese-skk-auto-fill"		; (skk-auto-fill-mode 1)
      )

;; SKK を起動していなくても、いつでも skk-isearch を使う
(defvar skk-isearch-mode-enable 'always)

;; @@ 応用的な設定

;; ~/.skk* なファイルがたくさんあるので整理したい
(defvar skk-user-directory "~/.emacs.d/.ddskk")

;; 注 1) 上記の設定をした場合、~/.skk や ~/.skk-jisyo の代わりに
;;       ~/.ddskk/init や ~/.ddskk/jisyo が使われます。ただし、
;;       これらのファイル名を個別に設定している場合はその設定が優先
;;       されるので注意してください。また、~/.skk や ~/.skk-jisyo を
;;       既にもっている場合は手動でコピーする必要があります。
;;       -- 影響を受ける変数の一覧 --
;;          skk-init-file, skk-jisyo, skk-backup-jisyo
;;          skk-emacs-id-file. skk-record-file,
;;          skk-study-file, skk-study-backup-file
;; 注 2) SKK の個人辞書は skkinput などのプログラムでも参照しますから、
;;       上記の設定をした場合はそれらのプログラムの設定ファイルも書き
;;       換える必要があります。

;; migemo を使うから skk-isearch にはおとなしくしていて欲しい
;(setq skk-isearch-start-mode 'latin)

;; YaTeX のときだけ句読点を変更したい
;(add-hook 'yatex-mode-hook
;	  (lambda ()
;	    (require 'skk)
;	    (setq skk-kutouten-type 'en)))

;; 文章系のバッファを開いた時には自動的に英数モード(「SKK」モード)に入る
;(let ((function #'(lambda ()
;		    (require 'skk)
;		    (skk-latin-mode-on))))
;  (dolist (hook '(find-file-hooks
;		  ;; ...
;		  mail-setup-hook
;		  message-setup-hook))
;    (add-hook hook function)))

;; Emacs 起動時に SKK を前もってロードする
(defvar skk-preload t)
;; 注) skk.el をロードするだけなら (require 'skk) でもよい。上記設定の
;; 場合は、skk-search-prog-list に指定された辞書もこの時点で読み込んで
;; 準備する。Emacs の起動は遅くなるが，SKK を使い始めるときのレスポンス
;; が軽快になる。

;;; markdown
;;; Note: GitHub Flavored Markdown は gfm-mode を使う
(autoload 'markdown-mode "markdown-mode" "Major mode for editing Markdown files" t)
(setq auto-mode-alist (cons '("\\.md" . markdown-mode) auto-mode-alist))

;;; Makfile mode
(add-to-list 'auto-mode-alist '("Makefile\\..*$" . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("Makefile_.*$" . makefile-gmake-mode))

;;; shell-script mode
(add-to-list 'auto-mode-alist '("\.sh$" . shell-script-mode))

;;;
;;; autoinsert (http://d.hatena.ne.jp/higepon/20080731/1217491155)
;;;
(require 'autoinsert)

;; テンプレートのディレクトリ
(setq auto-insert-directory "~/.emacs.d/templates/")

;; 各ファイルによってテンプレートを切り替える
(setq auto-insert-alist
      (nconc '(
               ("\\.c$" . ["template.c" my-template])
               ("\\.cpp$" . ["template.cpp" my-template])
               ("\\.groovy$" . ["template.groovy" my-template])
               ("\\.h$"   . ["template.h" my-template])
               ("\\.java$" . ["template.java" my-template])
               ("\\.json$" . ["template.json" my-template])
               ("\\.org$" . ["template.org" my-template])
               ("\\.uml$" . ["template.uml" my-template])
               ("\\.sh$" . ["template.sh" my-template])
               ) auto-insert-alist))

;; ここが腕の見せ所
(defvar template-replacements-alists
  '(("%file%"             . (lambda () (file-name-nondirectory (buffer-file-name))))
    ("%file-without-ext%" . (lambda () (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))
    ("%include-guard%"    . (lambda () (format "_%s_INCLUDED_" (upcase (file-name-sans-extension (file-name-nondirectory buffer-file-name))))))))

(defun my-template ()
  "My template."
  (time-stamp)
  (mapc #'(lambda(c)
        (progn
          (goto-char (point-min))
;          (replace-string (car c) (funcall (cdr c)) nil)))
          (while (re-search-forward (car c) nil t)
            (replace-match (funcall (cdr c)) nil t))))
    template-replacements-alists)
  (goto-char (point-max))
  (message "done."))
(add-hook 'find-file-not-found-hooks 'auto-insert)

;;; JSON
(require 'json-mode)

;;; Cygwin Shell
(setq explicit-bash-args '("--login" "-i"))
(defun cygwin-shell ()
  "Run cygwin bash in shell mode."
  (interactive)
  (let ((explicit-shell-file-name "C:/cygwin/bin/bash"))
    (call-interactively 'shell)))

;;; C-x C-f を便利にする
(ffap-bindings)

;;; dired
(setq dired-listing-switches (purecopy "-Ahl"))

;; diredを2つのウィンドウで開いている時に、デフォルトの移動orコピー先を
;; もう一方のdiredで開いているディレクトリにする
(setq dired-dwim-target t)

;; ディレクトリを再帰的にコピーする
(setq dired-recursive-copies 'always)

;; diredバッファでC-sした時にファイル名だけにマッチするように
(defvar dired-isearch-filenames t)

;; .zipで終わるファイルをZキーで展開できるように
(defvar dired-compress-file-suffixes nil)
(add-to-list 'dired-compress-file-suffixes '("\\.zip\\'" ".zip" "unzip"))

;; マークされたファイルを tar. C-u をつけると tar.gz.
(defvar dired-guess-shell-gnutar "/bin/tar")
(defun dired-tar (tarname files &optional arg)
  "A dired-mode extension to archive files marked. With prefix argument, the tarball is gziped."
  (interactive (let ((files (dired-get-marked-files)))
                 (list (read-string "Tarball name: " (concat (file-relative-name (car files)) ".tar.gz"))
                       files "P")))
  (let ((tar (if arg
                 (if dired-guess-shell-gnutar
                     (concat dired-guess-shell-gnutar " zcf %s %s")
                   "tar cf - %2s | gzip &gt; %1s")
               "tar cf %s %s")))
    (shell-command (format tar tarname (mapconcat 'file-relative-name files " ")))))


;; ファイルを w3m で開く
(defun dired-w3m-find-file ()
  "ファイルを w3m で開く."
  (interactive)
  (require 'w3m)
  (let ((file (dired-get-filename)))
    (if (y-or-n-p (format "Open 'w3m' %s " (file-name-nondirectory file)))
        (w3m-find-file file))))


;; キーバインド
(eval-after-load "dired"
  '(define-key dired-mode-map "\C-xm" 'dired-w3m-find-file))
(eval-after-load "dired"
  '(define-key dired-mode-map "z" 'dired-zip-files))
(eval-after-load "dired"
  '(define-key dired-mode-map "r" 'wdired-change-to-wdired-mode))
(eval-after-load "dired"
  '(define-key dired-mode-map "\C-xt" 'dired-tar))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(display-time-mode t)
 '(show-paren-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; grep
(define-key global-map (kbd "C-x g") 'grep)
(require 'grep)
(setq grep-command "grep -nH -r -e ")
;(setq grep-command-before-query "grep -nH -r -e ")
;(defun grep-default-command ()
;  (if current-prefix-arg
;      (let ((grep-command-before-target
;             (concat grep-command-before-query
;                     (shell-quote-argument (grep-tag-default)))))
;        (cons (if buffer-file-name
;                  (concat grep-command-before-target
;                          " *."
;                          (file-name-extension buffer-file-name))
;                (concat grep-command-before-target " ."))
;              (+ (length grep-command-before-target) 1)))
;    (car grep-command)))
;(setq grep-command (cons (concat grep-command-before-query " .")
;                         (+ (length grep-command-before-query) 1)))
;

;;; flycheck
(add-hook 'after-init-hook #'global-flycheck-mode)

;;; golang
(require 'go-mode-autoloads)

;; 必要なパッケージのロード
(require 'go-mode)
(require 'company-go)
(require 'golint)

;; 諸々の有効化、設定
;;(add-hook 'go-mode-hook 'company-mode)
;;(add-hook 'go-mode-hook 'flycheck-mode)
(add-hook 'go-mode-hook (lambda()
                          (add-hook 'before-save-hook 'gofmt-before-save)
                          (local-set-key (kbd "M-.") 'godef-jump)
                          (set (make-local-variable 'company-backends) '(company-go))
                          (company-mode)
                          (setq indent-tabs-mode nil)    ; タブを利用
                          (setq c-basic-offset 4)        ; tabサイズを4にする
                          (setq tab-width 4)))

;;; yaml
(require 'yaml-mode)

(provide 'init)

;;; init.el ends here
