(uiop:define-package #:40ants-routes/with-routes
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:collection-namespace)
  (:export #:with-routes
           #:*current-namespace*
           #:*current-routes*
           #:register-routes))
(in-package #:40ants-routes/with-routes)

;; Dynamic variables to store current context
(defvar *current-namespace* nil
  "Current namespace for route resolution.")

(defvar *current-routes* nil
  "Current route collection for route resolution.")

;; Registry of all route collections (replaces global registry)
(defvar *route-collections* (make-hash-table :test 'equal)
  "Registry of all route collections, keyed by namespace.")

(defun register-routes (routes)
  "Register a route collection for later use."
  (setf (gethash (collection-namespace routes) *route-collections*)
        routes)
  routes)

;; Context management
(defmacro with-routes ((routes) &body body)
  "Execute body with the given routes object as the current routes context."
  `(let ((*current-namespace* (collection-namespace ,routes))
         (*current-routes* ,routes))
     ,@body))
