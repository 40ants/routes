(uiop:define-package #:40ants-routes/with-routes
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:collection-namespace
                #:collection-routes)
  (:export #:with-routes
           #:*current-namespace*
           #:*current-routes*
           #:*route-collections*
           #:register-routes
           #:find-collection-by-namespace))
(in-package #:40ants-routes/with-routes)

;; Dynamic variables to store current context
(defvar *current-namespace* nil
  "Current namespace for route resolution.")

(defvar *current-routes* nil
  "Current route collection for route resolution.")

;; Dynamic variable to store route collections in the current environment
(defvar *route-collections* nil
  "List of route collections in the current environment.")

(defun register-routes (routes)
  "Register a route collection for the current environment."
  (pushnew routes *route-collections*)
  routes)

(defun find-collection-by-namespace (namespace)
  "Find a route collection by namespace in the current environment."
  (find namespace *route-collections* 
        :key #'collection-namespace 
        :test #'string=))

;; Context management
(defmacro with-routes ((routes) &body body)
  "Execute body with the given routes object as the current routes context."
  `(let ((*current-namespace* (collection-namespace ,routes))
         (*current-routes* ,routes)
         (*route-collections* (cons ,routes *route-collections*)))
     ,@body))
