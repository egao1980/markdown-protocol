(defsystem "markdown-protocol"
  :version "0.2.0"
  :description "CommonMark-subset markdown parser (plus GFM tables and ~~strike~~) producing a plain-list block / inline AST"
  :author "egao1980"
  :license "MIT"
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "inline")
               (:file "block")
               (:file "markdown"))
  :in-order-to ((test-op (test-op "markdown-protocol/tests"))))

(defsystem "markdown-protocol/tests"
  :depends-on ("markdown-protocol" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "block-test")
               (:file "inline-test")
               (:file "document-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
