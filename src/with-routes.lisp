(uiop:define-package #:40ants-routes/with-routes
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:collection-namespace
                #:collection-routes)
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

;; Context management
(defmacro with-routes ((routes) &body body)
  "Execute body with the given routes object as the current routes context."
  (let ((routes-var (gensym "ROUTES")))
    `(let* ((,routes-var ,routes)
            (*current-namespace* (collection-namespace ,routes-var))
            (*current-routes* ,routes-var))
       ,@body)))
