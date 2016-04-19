(cl:in-package :cl-user)

#-asdf(require :asdf)

#-uiop(require :uiop)

(defpackage :lem-asd
  (:use :cl :asdf))

(in-package :lem-asd)

(defsystem lem
           :serial t
           :components ((:file "winsize")
                        (:file "fatstring")
                        (:file "queue")
                        (:file "util")
                        (:file "package")
                        (:file "errors")
                        (:file "term")
                        (:file "header")
                        (:file "wide")
                        (:file "key")
                        (:file "point")
                        (:file "overlay")
                        (:file "hooks")
                        (:file "timer")
                        (:file "marker")
                        (:file "keymap")
                        (:file "defcommand")
                        (:file "comp")
                        (:file "buffer")
                        (:file "syntax")
                        (:file "mode")
                        (:file "minibuf")
                        (:file "kill")
                        (:file "region")
                        (:file "io")
                        (:file "buffers")
                        (:file "basic")
                        (:file "command")
                        (:file "display")
                        (:file "window")
                        (:file "file")
                        (:file "file-command")
                        (:file "word")
                        (:file "search")
                        (:file "info-mode")
                        (:file "sexp")
                        (:file "grep")
                        (:file "abbrev")
                        (:file "prog-mode")
                        (:file "listener-mode")
                        (:file "dired")
                        (:file "lem")
                        (:file "list-buffers")
                        (:file "lisp-mode")
                        (:file "c-mode")
                        (:file "python-mode")
                        (:file "lua-mode"))
           :depends-on (:cl-charms
                        :cl-fad
                        :osicat
                        #+sbcl :sb-posix
                        #+sbcl :sb-introspect
                        :swank
                        :trivial-gray-streams
                        :cl-ppcre
                        :inquisitor
                        :babel))
