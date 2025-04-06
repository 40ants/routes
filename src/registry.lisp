(uiop:define-package #:40ants-routes/registry
  (:use #:cl)
  (:export #:*routes-registry*))
(in-package #:40ants-routes/registry)

;; Global variable to store routes
(defvar *routes-registry* (make-hash-table :test 'equal)
  "Global registry of all route collections.")