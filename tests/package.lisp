(defpackage #:markdown-protocol/tests
  (:use #:cl #:rove)
  (:local-nicknames (#:md #:markdown-protocol)))
(in-package #:markdown-protocol/tests)

(defun nl (&rest lines)
  "LINES joined with #\\Newline, each followed by one."
  (format nil "~{~A~%~}" lines))
