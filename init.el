;; -*- lexical-binding: t -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                              Melpa Setup
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                              GUI Setup
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(scroll-bar-mode -1)
(tool-bar-mode -1)
(add-to-list 'default-frame-alist '(width  . 140))
(add-to-list 'default-frame-alist '(height . 60))
(add-to-list 'default-frame-alist '(top . 25))
(add-to-list 'default-frame-alist '(left . 350))
(setq visible-bell nil)
(setq ring-bell-function 'ignore)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                              Editor Setup
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'grep)
(require 'paren)

(add-to-list 'load-path "~/.emacs.d/lisp/")
(add-to-list 'load-path "/opt/ros/melodic/share/emacs/site-lisp/")
(prefer-coding-system 'utf-8)
(show-paren-mode 1)
(global-hl-line-mode 1)
(setq apropos-do-all 1)
(setq-default indent-tabs-mode nil)
(setq show-paren-when-point-inside-paren t)
(setq-default tab-width 4)
(setq backup-directory-alist
      `(("." . ,(concat user-emacs-directory "backups"))))

(dolist (dir '("~/.local/bin" "~/.cargo/bin" "/opt/ros/melodic/bin"))
  (add-to-list 'exec-path dir))
(setenv "PATH" (concat "~/.local/bin:~/.cargo/bin:/opt/ros/melodic/bin:"
                       (getenv "PATH")))

(grep-apply-setting 'grep-template "rg --vimgrep -i -w <R> <F>")
(grep-apply-setting 'grep-command "rg --vimgrep -i -w ")
(grep-apply-setting 'grep-use-null-device nil)(setq-default tab-width 4)

(defun self-format-comment ()
  "Formats a comment to a fill line."
  (interactive)
  (save-excursion
    (uncomment-region  (region-beginning) (region-end))
    (fill-region  (region-beginning) (region-end))
    (comment-region (region-beginning) (region-end))))

(defun self-highlight-c-function-calls ()
       (font-lock-add-keywords
        nil
        '(("\\(\\w+\\)\\s-*\\(\(\\|\{\\)" 1 font-lock-function-name-face))
        t))

(add-hook 'prog-mode-hook 'highlight-numbers-mode)
(add-hook 'prog-mode-hook 'auto-revert-mode)

(add-hook 'c++-mode-hook 'self-highlight-c-function-calls)
(add-hook 'csharp-mode-hook 'self-highlight-c-function-calls)

(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.pddl\\'" . lisp-mode))

(defmacro self-mode-align-with (regex-string)
  "Returns a command that will call `align-regexp' with
`regex-string' on the selected region."
  `(lambda ()
     (interactive)
     (align-regexp (region-beginning)
                   (region-end)
                   ,(concat "\\(\\s-*\\)" regex-string))))

(defun self-grep-symbol-at-point (&optional arg)
  "Performs a ripgrep search for the `symbol-at-point' as a whole
word search.

If no prefix `arg' is given then search will be performed within
the current directory.  If a prefix `arg' is given then the search
will start at `arg' parent directories (e.g. if `arg' is 2 then
'../..' will passed as the starting directory to search.
"
  (interactive "P")
  (let* ((count (if (equal nil arg)
                    0
                  (if (listp arg) (car arg) arg)))
         (dir (if (> count 0) ".." ".")))
    (dotimes (n count)
      (when (> (- count n) 1)
        (setq dir (concat "../" dir))))
    (grep (concat "rg --vimgrep -i -w "
                  (symbol-name (symbol-at-point))
                  " "
                  dir))))

(defun self-occur-symbol-at-point ()
  "Performs an occur search for the `symbol-at-point' surrounded by
reege word boundaries."
  (interactive)
  (occur (concat "\\b" (symbol-name (symbol-at-point)) "\\b")))

(defcustom self-build-file nil
  "Build file used for custom compiling.")

(defun self-compile ()
       "Make the current build."
       (interactive)
       (save-buffer)
       (compile self-build-file))

(defun self-guard-header ()
  "Inserts a guard header found a typical C/C++ header file."
  (interactive)
  (let* ((file (buffer-file-name))
         (base (file-name-base file))
         (ext  (file-name-extension file))
         (guard (concat "GUARD_" (upcase base) "_" (upcase ext))))
    (insert (concat "#ifndef " guard))
    (newline)
    (insert (concat "#define " guard))
    (newline)
    (newline)
    (insert (concat "#endif // " guard))))

(defun self-define-region (name)
  "Inserts '/**** BEGIN `name' ****/' and a corresponding 'END' comments
into the buffer at point.  If a region is selected then the 'BEGIN' and
'END' comments will be placed around that region.
"
  (interactive "sName: \n")
  (let* ((begin (concat "/**** BEGIN " name " ****/"))
         (end   (concat "/**** END " name " ****/")))
    (if (use-region-p)
        (let ((rb (region-beginning))
              (re (region-end)))
          (progn (goto-char rb)
                 (move-beginning-of-line nil)
                 (open-line 1)
                 (insert begin)
                 (goto-char re)
                 (move-end-of-line nil)
                 (newline)
                 (insert end)
                 (newline)))
      (progn (insert begin)
             (newline)
             (insert end)
             (newline)))))

(defun self-statement-annotate (&optional whole-statement)
  "Annotates the end of an if, while, or switch statement with a
comment.  For example,

    if (isTrue) {
        // long if block
        // ...
        // ...
        // ...    
    } // end if (isTrue)

By default this command will not put the expression (the '(isTrue)'
from the example) in the comment unless the universal-argument is
specified, which will bind `whole-statement' to non-nil.
"
  (interactive "P")
  (save-excursion
    (let ((end (end-of-line)))
      (beginning-of-line)
      (if (search-forward-regexp "\\(for\\|switch\\|if\\|while\\)\\s-*(\\(.+\\))" end t)
          (let ((match (match-string (if whole-statement 0 1))))
            (if (search-forward "{" nil t)
                (progn (backward-char)
                       (forward-sexp)
                       (insert (concat " // " match)))
              (message "No open switch curly bracket found.")))
        (message "No statement found.")))))

(defun self-remove-dos-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(defun self-send-quit-other-window ()
  "Switches to the other window, call `quit-restore-window', and
return to the previous window."
  (interactive)
  (other-window 1)
  (quit-window))

(require 'comma-mode)
(require 'cl)

(dolist (hook '(emacs-lisp-mode-hook
                org-mode-hook
                prog-mode-hook
                text-mode-hook))
  (add-hook hook 'comma-mode))

(define-key comma-mode-map (kbd "c g")   'self-grep-symbol-at-point)
(define-key comma-mode-map (kbd "c G")   'grep)
(define-key comma-mode-map (kbd "c o")   'self-occur-symbol-at-point)
(define-key comma-mode-map (kbd "c O")   'occur)
(define-key comma-mode-map (kbd "c t")   'xref-find-apropos)
(define-key comma-mode-map (kbd "c s")   'magit-status)
(define-key comma-mode-map (kbd "c S")   'magit-dispatch)
(define-key comma-mode-map (kbd "c b")   'magit-blame)
(define-key comma-mode-map (kbd "c a")   'align)
(define-key comma-mode-map (kbd "c r")   'align-regexp)
(define-key comma-mode-map (kbd "c i")   'imenu)
;; (define-key comma-mode-map (kbd "c :")   (comma-mode-align-with ":"))
;; (define-key comma-mode-map (kbd "c =")   (comma-mode-align-with "="))
(define-key comma-mode-map (kbd "c x")   'self-compile)
(define-key comma-mode-map (kbd "c w")   'toggle-truncate-lines)
(define-key comma-mode-map (kbd "c c")   'comment-region)
(define-key comma-mode-map (kbd "c u")   'uncomment-region)
(define-key comma-mode-map (kbd "c q")   'self-send-quit-other-window)
(define-key comma-mode-map (kbd "c M-p") 'beginning-of-buffer-other-window)
(define-key comma-mode-map (kbd "c M-n") 'end-of-buffer-other-window)

;; ====================> END COMMA-MODE KEYMAP DEFINITIONS <====================


(use-package which-key
  :ensure t
  :init
  (which-key-mode))

(use-package ace-window
  :ensure t
  :init
  (setq aw-dispatch-always t)
  (global-set-key (kbd "M-o") 'ace-window))

(use-package ivy
  :ensure t)

(use-package counsel
  :ensure t
  :init
  (counsel-mode 1)
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (global-set-key (kbd "C-s") 'swiper)
  (global-set-key (kbd "C-r") 'swiper)
  (global-set-key (kbd "C-c g") 'counsel-git)
  (global-set-key (kbd "C-c G") 'counsel-git-grep))

(use-package go-mode
  :init
  :bind (:map go-mode-map
              ("M-q" . self-format-comment)
              :map comma-mode-map
              ("x g" . gofmt)))


;; START: Stays within init.el
(global-set-key (kbd "M-/") 'hippie-expand)
(if (display-graphic-p)
    (progn
      (global-set-key (kbd "C-,") 'comma-mode)
      (load-theme 'base16-porple t))
  (progn
    (load-theme 'misterioso t)
    (global-set-key (kbd "C-c ,") 'comma-mode)))

;;;; Run this command in GDB to open a new console window to see
;;;; stdout:
;;;;
;;;; (gdb) set new-console on

(add-hook
 'gdb-mode-hook
 '(lambda ()         
    (defun gdb-setup-windows ()
      "Layout the window pattern for option `gdb-many-windows'."
      (gdb-get-buffer-create 'gdb-locals-buffer)
      (gdb-get-buffer-create 'gdb-stack-buffer)
      (gdb-get-buffer-create 'gdb-breakpoints-buffer)
      (gdb-get-buffer-create 'gdb-disassembly-buffer)
      (set-window-dedicated-p (selected-window) nil)
      (switch-to-buffer gud-comint-buffer)
      (delete-other-windows)
      (let ((win0 (selected-window))
            (win1 (split-window nil ( / ( * (window-height) 3) 4)))
            (win2 (split-window nil ( / (window-height) 3)))
            (win3 (split-window-right)))
        (gdb-set-window-buffer (gdb-locals-buffer-name) nil win3)
        (select-window win2)
        (set-window-buffer
         win2
         (if gud-last-last-frame
             (gud-find-file (car gud-last-last-frame))
           (if gdb-main-file
               (gud-find-file gdb-main-file)
             ;; Put buffer list in window if we
             ;; can't find a source file.
             (list-buffers-noselect))))
        (setq gdb-source-window (selected-window))
        (let ((win4 (split-window-right)))
          (gdb-set-window-buffer (gdb-disassembly-buffer-name) nil win4))
        (select-window win1)
        (gdb-set-window-buffer (gdb-stack-buffer-name))
        (let ((win5 (split-window-right)))
          (gdb-set-window-buffer (if gdb-show-threads-by-default
                                     (gdb-threads-buffer-name)
                                   (gdb-breakpoints-buffer-name))
                                 nil win5))
        (select-window win0)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                              Rust
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package rust-mode
  :ensure t
  :init
  :bind (:map rust-mode-map
              ("M-q" . self-format-comment)
              :map comma-mode-map
              ("x g" . cargo-format)))

(defun cargo-test ()
  (interactive)
  ;; (compile "cargo test -q -- --nocapture"))
  (shell "*CARGO-TEST*")
  (comint-clear-buffer)
  (comint-send-input)
  (insert "cargo test -q -- --nocapture")
  (comint-send-input))

(defun cargo-format ()
  "`CARGO-FORMAT' runs rustfmt on the entire project directory by calling
'cargo +nightly fmt' with emacs' `COMPILE' command.  The command searches
for the root directory of the project by searching for the 'Cargo.toml' file
and is such file is not found then the formatting is not run.  If any errors
are encountered during the formatting operation the results will be displayed
in the `*compilation*'."
  (interactive)
  (let* ((curr-dir (cd "."))
         (main-dir nil))
    (do ((dir (cd ".")))
        ((or (string= dir "/")
             (not (eq main-dir nil))))
      (if (file-exists-p "Cargo.toml")
          (setf main-dir dir)
        (setf dir (cd ".."))))
    (if (eq main-dir nil)
        (message "[cargo-format] Can't find project root directory")
      (progn
        (setq compilation-finish-function
              (lambda (buf str)
                (if (null (string-match ".*exited abnormally.*" str))
                    (progn
                      (delete-window (get-buffer-window "*compilation*"))
                      (message "[cargo-format] Formatting complete")))))
        (compile "cargo +nightly fmt")
        (cd curr-dir)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                              SUBT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
(defun subt-cmu-build (&optional package)
  (interactive "spackage: ")
  (let ((deps "--no-deps"))
    (unless package
      (setf package ""))
    (when (string= package "")
      (setf deps ""))
    (shell "*ROS_LAUNCH-CMU-Build*")
    (toggle-truncate-lines 1)
    (comint-clear-buffer) ;; in case of re-using previous shell
    (comint-send-input)   ;; reset prompt so next insert is placed in the correct spot
    (insert (concat "cd ~/workspace/subt_new; "
                    "source devel/setup.bash; "
                    "catkin build " package "; "
                    "catkin build " package " -i " deps " --catkin-make-args run_tests; "
                    "catkin_test_results build/" package))
    (comint-send-input)))

;; END: Stays within init.el



(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#f8f8f8" "#ab4642" "#538947" "#f79a0e" "#7cafc2" "#96609e" "#7cafc2" "#383838"])
 '(ansi-term-color-vector
   [unspecified "#f8f8f8" "#ab4642" "#538947" "#f79a0e" "#7cafc2" "#96609e" "#7cafc2" "#383838"] t)
 '(c-basic-offset 4)
 '(c-default-style
   (quote
    ((c++-mode . "stroustrup")
     (java-mode . "java")
     (awk-mode . "awk")
     (other . "stroustrup"))))
 '(c-doc-comment-style
   (quote
    ((c-mode . javadoc)
     (c++-mode . javadoc)
     (java-mode . javadoc)
     (pike-mode . autodoc))))
 '(c-hanging-braces-alist (quote set-from-style))
 '(c-offsets-alist
   (quote
    ((extern-lang-open . 0)
     (namespace-open . 0)
     (extern-lang-close . 0)
     (namespace-close . 0)
     (inextern-lang . 0)
     (innamespace . 0))))
 '(column-number-mode t)
 '(compilation-error-regexp-alist
   (quote
    (absoft ada aix ant bash borland python-tracebacks-and-caml comma cucumber msft edg-1 edg-2 epc ftnchek iar ibm irix java jikes-file maven jikes-line gcc-include ruby-Test::Unit gnu lcc makepp mips-1 mips-2 msft omake oracle perl php rxp sparc-pascal-file sparc-pascal-line sparc-pascal-example sun sun-ada watcom 4bsd gcov-file gcov-header gcov-nomark gcov-called-line gcov-never-called perl--Pod::Checker perl--Test perl--Test2 perl--Test::Harness weblint guile-file guile-line nim)))
 '(compilation-message-face (quote default))
 '(custom-safe-themes
   (quote
    ("7a1190ad27c73888f8d16142457f59026b01fa654f353c17f997d83565c0fc65" "aea30125ef2e48831f46695418677b9d676c3babf43959c8e978c0ad672a7329" "ed36f8e30f02520ec09be9d74fe2a49f99ce85a3dfdb3a182ccd5f182909f3ab" "ecfd522bd04e43c16e58bd8af7991bc9583b8e56286ea0959a428b3d7991bbd8" "c614d2423075491e6b7f38a4b7ea1c68f31764b9b815e35c9741e9490119efc0" "ddd5045ceb90356295b99a4da14200604bfc1dd658a3af568bd8a9961a5c4e5f" "8be07a2c1b3a7300860c7a65c0ad148be6d127671be04d3d2120f1ac541ac103" "224065fc5797fba359a4be000fc7952d49995ce8d4132114fb0ecc7d2cb84cce" "aded4ec996e438a5e002439d58f09610b330bbc18f580c83ebaba026bbef6c82" "85e6bb2425cbfeed2f2b367246ad11a62fb0f6d525c157038a0d0eaaabc1bfee" "4a91a64af7ff1182ed04f7453bb5a4b0c3d82148d27db699df89a5f1d449e2a4" "8543b328ed10bc7c16a8a35c523699befac0de00753824d7e90148bca583f986" "3f67aee8f8d8eedad7f547a346803be4cc47c420602e19d88bdcccc66dba033b" "5b8eccff13d79fc9b26c544ee20e1b0c499587d6c4bfc38cabe34beaf2c2fc77" "ffe80c88e3129b2cddadaaf78263a7f896d833a77c96349052ad5b7753c0c5a5" "3de3f36a398d2c8a4796360bfce1fa515292e9f76b655bb9a377289a6a80a132" "722e1cd0dad601ec6567c32520126e42a8031cd72e05d2221ff511b58545b108" "8578750fb94f908249a98dc14c3847d11863196f54de87a037b1374f2ae1f534" "1d079355c721b517fdc9891f0fda927fe3f87288f2e6cc3b8566655a64ca5453" "92192ea8f0bf04421f5b245d906701abaa7bb3b0d2b3b14fca2ee5ebb1da38d8" "b3bcf1b12ef2a7606c7697d71b934ca0bdd495d52f901e73ce008c4c9825a3aa" "ccde32eaf485eb7579412cd756d10b0f20f89bff07696972d7ee46cb2e10b89d" "5f99055206ed6a1b9958f7dd5eaa9f884f8b5a8678bd0c5e2622aced5c4a1be7" "5228973368d5a1ac0cbea0564d0cd724937f52cc06a8fd81fc65a4fa72ff837b" "45a8b89e995faa5c69aa79920acff5d7cb14978fbf140cdd53621b09d782edcf" "542e6fee85eea8e47243a5647358c344111aa9c04510394720a3108803c8ddd1" "e04cdda50908b116031c09d7b316fff5d8f9bc6e2126411c9316969461bfd8b6" "b8929cff63ffc759e436b0f0575d15a8ad7658932f4b2c99415f3dde09b32e97" "2a998a3b66a0a6068bcb8b53cd3b519d230dd1527b07232e54c8b9d84061d48d" "85d609b07346d3220e7da1e0b87f66d11b2eeddad945cac775e80d2c1adb0066" "5a39d2a29906ab273f7900a2ae843e9aa29ed5d205873e1199af4c9ec921aaab" "e1498b2416922aa561076edc5c9b0ad7b34d8ff849f335c13364c8f4276904f0" "50d07ab55e2b5322b2a8b13bc15ddf76d7f5985268833762c500a90e2a09e7aa" "d9dab332207600e49400d798ed05f38372ec32132b3f7d2ba697e59088021555" "250268d5c0b4877cc2b7c439687f8145a2c85a48981f7070a72c7f47a2d2dc13" "5a7830712d709a4fc128a7998b7fa963f37e960fd2e8aa75c76f692b36e6cf3c" "527df6ab42b54d2e5f4eec8b091bd79b2fa9a1da38f5addd297d1c91aa19b616" "78c1c89192e172436dbf892bd90562bc89e2cc3811b5f9506226e735a953a9c6" "6145e62774a589c074a31a05dfa5efdf8789cf869104e905956f0cbd7eda9d0e" "4bf5c18667c48f2979ead0f0bdaaa12c2b52014a6abaa38558a207a65caeb8ad" "df21cdadd3f0648e3106338649d9fea510121807c907e2fd15565dde6409d6e9" "50b64810ed1c36dfb72d74a61ae08e5869edc554102f20e078b21f84209c08d1" "f869a5d068a371532c82027cdf1feefdc5768757c78c48a7e0177e90651503ad" "986e7e8e428decd5df9e8548a3f3b42afc8176ce6171e69658ae083f3c06211c" "87d46d0ad89557c616d04bef34afd191234992c4eb955ff3c60c6aa3afc2e5cc" "7bef2d39bac784626f1635bd83693fae091f04ccac6b362e0405abf16a32230c" "34ed3e2fa4a1cb2ce7400c7f1a6c8f12931d8021435bad841fdc1192bd1cc7da" "760ce657e710a77bcf6df51d97e51aae2ee7db1fba21bbad07aab0fa0f42f834" "52741e091463c2217af9327e2b2d74d0df861ecc3ad6131b6cbcb8d76b7a4d3d" "159aab698b9d3fb03b495ce3af2d298f4c6dfdf21b53c27cd7f472ee5a1a1de3" "9955cc54cc64d6c051616dce7050c1ba34efc2b0613d89a70a68328f34e22c8f" "fec45178b55ad0258c5f68f61c9c8fd1a47d73b08fb7a51c15558d42c376083d" "1263771faf6967879c3ab8b577c6c31020222ac6d3bac31f331a74275385a452" "6daa09c8c2c68de3ff1b83694115231faa7e650fdbb668bc76275f0f2ce2a437" "4feee83c4fbbe8b827650d0f9af4ba7da903a5d117d849a3ccee88262805f40d" "fee4e306d9070a55dce4d8e9d92d28bd9efe92625d2ba9d4d654fc9cd8113b7f" "d83e34e28680f2ed99fe50fea79f441ca3fddd90167a72b796455e791c90dc49" "100eeb65d336e3d8f419c0f09170f9fd30f688849c5e60a801a1e6addd8216cb" "ad16a1bf1fd86bfbedae4b32c269b19f8d20d416bd52a87cd50e355bf13c2f23" "cea3ec09c821b7eaf235882e6555c3ffa2fd23de92459751e18f26ad035d2142" "f78de13274781fbb6b01afd43327a4535438ebaeec91d93ebdbba1e3fba34d3c" "60e09d2e58343186a59d9ed52a9b13d822a174b33f20bdc1d4abb86e6b17f45b" "a85e40c7d2df4a5e993742929dfd903899b66a667547f740872797198778d7b5" "0c3b1358ea01895e56d1c0193f72559449462e5952bded28c81a8e09b53f103f" "25c242b3c808f38b0389879b9cba325fb1fa81a0a5e61ac7cae8da9a32e2811b" "d9850d120be9d94dd7ae69053630e89af8767c36b131a3aa7b06f14007a24656" "36746ad57649893434c443567cb3831828df33232a7790d232df6f5908263692" "8cf1002c7f805360115700144c0031b9cfa4d03edc6a0f38718cef7b7cabe382" "4d99377c78202743003ab19f51ea5d57b59811de09803ef981067f1bba6fd6a0" "788f25d96750d1ad160c1971edb9fb8f2958985b10eb7327e55f4cbf228922e7" "c968804189e0fc963c641f5c9ad64bca431d41af2fb7e1d01a2a6666376f819c" "938d8c186c4cb9ec4a8d8bc159285e0d0f07bad46edf20aa469a89d0d2a586ea" "82d2cac368ccdec2fcc7573f24c3f79654b78bf133096f9b40c20d97ec1d8016" "08b8807d23c290c840bbb14614a83878529359eaba1805618b3be7d61b0b0a32" "bcc6775934c9adf5f3bd1f428326ce0dcd34d743a92df48c128e6438b815b44f" "9d91458c4ad7c74cf946bd97ad085c0f6a40c370ac0a1cbeb2e3879f15b40553" "c7a9a68bd07e38620a5508fef62ec079d274475c8f92d75ed0c33c45fbe306bc" "eb0a314ac9f75a2bf6ed53563b5d28b563eeba938f8433f6d1db781a47da1366" "3380a2766cf0590d50d6366c5a91e976bdc3c413df963a0ab9952314b4577299" "628278136f88aa1a151bb2d6c8a86bf2b7631fbea5f0f76cba2a0079cd910f7d" "06f0b439b62164c6f8f84fdda32b62fb50b6d00e8b01c2208e55543a6337433a" "eae831de756bb480240479794e85f1da0789c6f2f7746e5cc999370bbc8d9c8a" "bffa9739ce0752a37d9b1eee78fc00ba159748f50dc328af4be661484848e476" default)))
 '(fci-rule-color "#373b41")
 '(highlight-changes-colors (quote ("#FD5FF0" "#AE81FF")))
 '(highlight-tail-colors
   (quote
    (("#3C3D37" . 0)
     ("#679A01" . 20)
     ("#4BBEAE" . 30)
     ("#1DB4D0" . 50)
     ("#9A8F21" . 60)
     ("#A75B00" . 70)
     ("#F309DF" . 85)
     ("#3C3D37" . 100))))
 '(inhibit-startup-screen t)
 '(magit-diff-use-overlays nil)
 '(package-selected-packages
   (quote
    (yaml-mode toml-mode counsel ace-window which-key rust-mode cmake-mode js2-mode lua-mode magit magit-popup go-mode go-scratch quickrun kaolin-theme use-package cargo csharp-mode highlight-numbers highlight-quoted monokai-theme base16-theme)))
 '(pos-tip-background-color "#A6E22E")
 '(pos-tip-foreground-color "#272822")
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(vc-annotate-background nil)
 '(vc-annotate-color-map
   (quote
    ((20 . "#F92672")
     (40 . "#CF4F1F")
     (60 . "#C26C0F")
     (80 . "#E6DB74")
     (100 . "#AB8C00")
     (120 . "#A18F00")
     (140 . "#989200")
     (160 . "#8E9500")
     (180 . "#A6E22E")
     (200 . "#729A1E")
     (220 . "#609C3C")
     (240 . "#4E9D5B")
     (260 . "#3C9F79")
     (280 . "#A1EFE4")
     (300 . "#299BA6")
     (320 . "#2896B5")
     (340 . "#2790C3")
     (360 . "#66D9EF"))))
 '(vc-annotate-very-old-color nil)
 '(weechat-color-list
   (unspecified "#272822" "#3C3D37" "#F70057" "#F92672" "#86C30D" "#A6E22E" "#BEB244" "#E6DB74" "#40CAE4" "#66D9EF" "#FB35EA" "#FD5FF0" "#74DBCD" "#A1EFE4" "#F8F8F2" "#F8F8F0")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Ubuntu Mono" :foundry "DAMA" :slant normal :weight bold :height 120 :width normal)))))
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
