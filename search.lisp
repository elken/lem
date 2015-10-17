;; -*- Mode: Lisp; Package: Lem -*-

(in-package :lem)

(export '(*isearch-keymap*
          isearch-mode
          isearch-forward
          isearch-backward
          isearch-abort
          isearch-delete-char
          isearch-raw-insert
          isearch-end
          isearch-next
          isearch-prev
          isearch-yank
          isearch-self-insert
          search-forward
          search-backward
          query-replace))

(defvar *isearch-keymap* (make-keymap "isearch" 'isearch-self-insert))
(defvar *isearch-prompt*)
(defvar *isearch-string*)
(defvar *isearch-prev-string* "")
(defvar *isearch-start-point*)
(defvar *isearch-search-function*)
(defvar *isearch-search-forward-function*)
(defvar *isearch-search-backward-function*)
(defvar *isearch-highlight-overlays* nil)

(define-minor-mode isearch-mode
  :name "isearch"
  :keymap *isearch-keymap*)

(defun isearch-update-display ()
  (isearch-update-minibuf)
  (isearch-update-buffer)
  (setf (window-redraw-flag) :all))

(defun isearch-update-minibuf ()
  (minibuf-print
   (format nil "~a~a"
           *isearch-prompt*
           *isearch-string*)))

(define-key *global-keymap* (kbd "C-s") 'isearch-forward)
(define-command isearch-forward () ()
  (isearch-start
   "ISearch: "
   #'(lambda (str)
       (prev-char (length str))
       (search-forward str))
   #'search-forward
   #'search-backward))

(define-key *global-keymap* (kbd "C-r") 'isearch-backward)
(define-command isearch-backward () ()
  (isearch-start
   "ISearch:"
   #'(lambda (str)
       (next-char (length str))
       (search-backward str))
   #'search-forward
   #'search-backward))

(define-key *global-keymap* (kbd "C-M-s") 'isearch-forward-regexp)
(define-command isearch-forward-regexp () ()
  (isearch-start "ISearch Regexp: "
                 #'re-search-forward
                 #'re-search-forward
                 #'re-search-backward))

(define-key *global-keymap* (kbd "C-M-r") 'isearch-backward-regexp)
(define-command isearch-backward-regexp () ()
  (isearch-start "ISearch Regexp: "
                 #'re-search-backward
                 #'re-search-forward
                 #'re-search-backward))

(define-key *global-keymap* (kbd "C-x C-M-s") 'isearch-symbol-forward)
(define-command isearch-symbol-forward () ()
  (isearch-start "ISearch Symbol: "
                 #'search-symbol-forward
                 #'search-symbol-forward
                 #'search-symbol-backward))

(define-key *global-keymap* (kbd "C-x C-M-r") 'isearch-symbol-backward)
(define-command isearch-symbol-backward () ()
  (isearch-start "ISearch Symbol: "
                 #'search-symbol-backward
                 #'search-symbol-forward
                 #'search-symbol-backward))

(defun isearch-start (prompt
                      search-func
                      search-forward-function
                      search-backward-function)
  (isearch-mode t)
  (setq *isearch-prompt* prompt)
  (setq *isearch-string* "")
  (isearch-update-minibuf)
  (setq *isearch-search-function* search-func)
  (setq *isearch-start-point* (point))
  (setq *isearch-search-forward-function* search-forward-function)
  (setq *isearch-search-backward-function* search-backward-function)
  t)

(define-key *isearch-keymap* (kbd "C-g") 'isearch-abort)
(define-command isearch-abort () ()
  (point-set *isearch-start-point*)
  t)

(define-key *isearch-keymap* (kbd "C-h") 'isearch-delete-char)
(define-key *isearch-keymap* (kbd "[backspace]") 'isearch-delete-char)
(define-key *isearch-keymap* (kbd "[del]") 'isearch-delete-char)
(define-command isearch-delete-char () ()
  (when (plusp (length *isearch-string*))
    (setq *isearch-string*
          (subseq *isearch-string*
                  0
                  (1- (length *isearch-string*))))
    (isearch-update-display)))

(define-key *isearch-keymap* (kbd "C-q") 'isearch-raw-insert)
(define-command isearch-raw-insert () ()
  (isearch-add-char (getch)))

(define-key *isearch-keymap* (kbd "C-j") 'isearch-end)
(define-key *isearch-keymap* (kbd "C-m") 'isearch-end)
(define-command isearch-end () ()
  (isearch-reset-buffer)
  (setq *isearch-prev-string* *isearch-string*)
  (isearch-mode nil))

(define-key *isearch-keymap* (kbd "C-s") 'isearch-next)
(define-command isearch-next () ()
  (when (string= "" *isearch-string*)
    (setq *isearch-string* *isearch-prev-string*))
  (funcall *isearch-search-forward-function* *isearch-string*)
  (isearch-update-display))

(define-key *isearch-keymap* (kbd "C-r") 'isearch-prev)
(define-command isearch-prev () ()
  (when (string= "" *isearch-string*)
    (setq *isearch-string* *isearch-prev-string*))
  (funcall *isearch-search-backward-function* *isearch-string*)
  (isearch-update-display))

(define-key *isearch-keymap* (kbd "C-y") 'isearch-yank)
(define-command isearch-yank () ()
  (let ((str (kill-ring-first-string)))
    (when str
      (setq *isearch-string* str)
      (isearch-update-display))))

(defun isearch-reset-buffer ()
  (mapc #'delete-overlay *isearch-highlight-overlays*)
  (setq *isearch-highlight-overlays* nil))

(defun isearch-update-buffer (&optional (search-string *isearch-string*))
  (isearch-reset-buffer)
  (window-adjust-view *current-window* t)
  (unless (equal "" search-string)
    (let ((save-point (point))
          start-point
          end-point)
      (with-window-range (start end) *current-window*
        (setq start-point (make-point start 0))
        (setq end-point (make-point (1+ end) 0))
        (point-set start-point)
        (do ()
            ((null
              (funcall *isearch-search-forward-function*
                       search-string end-point)))
          (let ((point2 (point))
                (point1 (save-excursion
                         (funcall *isearch-search-backward-function*
                                  search-string)
                         (point))))
            (push (make-overlay point1 point2
                                :attr (if (and (point<= point1 save-point)
                                               (point<= save-point point2))
                                          (get-attr :search-highlight)
                                          (get-attr :highlight)))
                  *isearch-highlight-overlays*))))
      (point-set save-point))))

(defun isearch-add-char (c)
  (setq *isearch-string*
        (concatenate 'string
                     *isearch-string*
                     (string c)))
  (isearch-update-display)
  (let ((point (point)))
    (unless (funcall *isearch-search-function* *isearch-string*)
      (point-set point))))

(define-command isearch-self-insert () ()
  (let ((c (insertion-key-p *last-input-key*)))
    (if c
        (isearch-add-char c)
        (progn
          (progn
            (isearch-update-display)
            (mapc 'ungetch (reverse (kbd-list *last-input-key*)))
            (isearch-end))))))

(defun search-step (first-search search step goto-matched-pos endp)
  (let ((point (point))
        (result
         (let ((res (funcall first-search)))
           (cond (res
                  (funcall goto-matched-pos res)
                  t)
                 (t
                  (do () ((funcall endp))
                    (unless (funcall step)
                      (return nil))
                    (let ((res (funcall search)))
                      (when res
                        (funcall goto-matched-pos res)
                        (return t)))))))))
    (unless result
      (point-set point))
    result))

(defun search-forward-endp-function (limit)
  (if limit
      #'(lambda ()
          (or (point< limit (point))
              (eobp)))
      #'eobp))

(defun search-forward (str &optional limit)
  (let ((length (1+ (count #\newline str))))
    (flet ((take-string ()
                        (join (string #\newline)
                              (buffer-take-lines (window-buffer)
                                                 (window-cur-linum)
                                                 length))))
      (search-step #'(lambda ()
                       (let ((pos
                              (search str (take-string)
                                      :start2 (window-cur-col))))
                         (when pos (+ pos (length str)))))
                   #'(lambda ()
                       (let ((pos (search str (take-string))))
                         (when pos (+ pos (length str)))))
                   #'next-line
                   #'goto-column
                   (search-forward-endp-function limit)))))

(defun search-backward-endp-function (limit)
  (if limit
      #'(lambda ()
          (point< (point) limit))
      #'bobp))

(defun search-backward (str &optional limit)
  (let ((length (1+ (count #\newline str))))
    (flet ((%search (&rest args)
                    (let ((linum (- (window-cur-linum) (1- length))))
                      (when (< 0 linum)
                        (apply 'search str
                               (join (string #\newline)
                                     (buffer-take-lines (window-buffer)
                                                        linum
                                                        length))
                               :from-end t
                               args)))))
      (search-step #'(lambda ()
                       (%search :end2 (window-cur-col)))
                   #'%search
                   #'prev-line
                   #'(lambda (i)
                       (and (prev-line (1- length))
                            (beginning-of-line)
                            (next-char i)))
                   (search-backward-endp-function limit)))))

(defun re-search-forward (regex &optional limit)
  (let (scanner)
    (handler-case (setq scanner (ppcre:create-scanner regex))
      (error () (return-from re-search-forward nil)))
    (search-step
     #'(lambda ()
         (multiple-value-bind (start end)
             (ppcre:scan scanner
                         (buffer-line-string (window-buffer)
                                             (window-cur-linum))
                         :start (window-cur-col))
           (when start end)))
     #'(lambda ()
         (multiple-value-bind (start end)
             (ppcre:scan scanner
                         (buffer-line-string (window-buffer)
                                             (window-cur-linum)))
           (when start end)))
     #'next-line
     #'goto-column
     (search-forward-endp-function limit))))

(defun re-search-backward (regex &optional limit)
  (let (scanner)
    (handler-case (setq scanner (ppcre:create-scanner regex))
      (error () (return-from re-search-backward nil)))
    (search-step
     #'(lambda ()
         (let (pos)
           (ppcre:do-scans (start
                            end
                            reg-starts
                            reg-ends
                            scanner
                            (buffer-line-string (window-buffer)
                                                (window-cur-linum))
                            nil
                            :end (window-cur-col))
             (declare (ignore end reg-starts reg-ends))
             (setq pos start))
           pos))
     #'(lambda ()
         (let (pos)
           (ppcre:do-scans (start
                            end
                            reg-starts
                            reg-ends
                            scanner
                            (buffer-line-string (window-buffer)
                                                (window-cur-linum))
                            nil
                            :start (window-cur-col))
             (declare (ignore end reg-starts reg-ends))
             (setq pos start))
           pos))
     #'prev-line
     #'goto-column
     (search-backward-endp-function limit))))

(let ((scanner "[a-zA-Z0-9+\\-<>/*&=.?_!$%:@\\[\\]^{}]+"))
  (defun search-symbol-positions (name &key start end)
    (let ((positions)
          (str (buffer-line-string (window-buffer)
                                   (window-cur-linum))))
      (ppcre:do-scans (start-var end-var reg-starts reg-ends scanner str nil
                                 :start start :end end)
        (declare (ignore end-var reg-starts reg-ends))
        (let ((str (subseq str start-var end-var)))
          (when (equal str name)
            (push (cons start-var end-var) positions))))
      (nreverse positions))))

(defun search-symbol-forward (name &optional limit)
  (search-step
   #'(lambda ()
       (cdar (search-symbol-positions name :start (window-cur-col))))
   #'(lambda ()
       (cdar (search-symbol-positions name)))
   #'next-line
   #'goto-column
   (search-forward-endp-function limit)))

(defun search-symbol-backward (name &optional limit)
  (search-step
   #'(lambda ()
       (caar (last (search-symbol-positions name :end (window-cur-col)))))
   #'(lambda ()
       (caar (last (search-symbol-positions name))))
   #'prev-line
   #'goto-column
   (search-backward-endp-function limit)))

(defvar *replace-before-string* nil)
(defvar *replace-after-string* nil)

(defun query-replace-before-after ()
  (let ((before)
        (after))
    (setq before
          (minibuf-read-string
           (if *replace-before-string*
               (format nil "Before (~a with ~a): "
                       *replace-before-string*
                       *replace-after-string*)
               "Before: ")))
    (when (equal "" before)
      (cond (*replace-before-string*
             (setq before *replace-before-string*)
             (setq after *replace-after-string*)
             (return-from query-replace-before-after
               (values before after)))
            (t
             (minibuf-print "Before string is empty")
             (return-from query-replace-before-after
               (values nil nil)))))
    (setq after (minibuf-read-string "After: "))
    (setq *replace-before-string* before)
    (setq *replace-after-string* after)
    (values before after)))

(defun query-replace-internal (search-forward-function
                               search-backward-function)
  (let ((*isearch-search-forward-function* search-forward-function)
        (*isearch-search-backward-function* search-backward-function))
    (multiple-value-bind (before after)
        (query-replace-before-after)
      (when (and before after)
        (do ((start-point)
             (end-point)
             (pass-through nil))
            ((null (funcall search-forward-function before)))
          (setq end-point (point))
          (isearch-update-buffer before)
          (minibuf-print (format nil "Replace ~s with ~s" before after))
          (funcall search-backward-function before)
          (setq start-point (point))
          (unless pass-through (window-update-all))
          (do () (nil)
            (let ((c (unless pass-through (getch))))
              (cond
               ((or pass-through (char= c #\y))
                (let ((*kill-disable-p* t))
                  (kill-region start-point end-point))
                (insert-string after)
                (return))
               ((char= c #\n)
                (point-set end-point)
                (return))
               ((char= c #\!)
                (setq pass-through t))))))
        (minibuf-clear))
      (isearch-reset-buffer)
      t)))

(define-key *global-keymap* (kbd "M-%") 'query-replace)
(define-command query-replace () ()
  (query-replace-internal #'search-forward #'search-backward))

(define-command query-replace-regexp () ()
  (query-replace-internal #'re-search-forward #'re-search-backward))
