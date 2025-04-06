(uiop:define-package #:40ants-routes/with-routes
  (:use #:cl)
  (:import-from #:40ants-routes/route-collection
                #:collection-namespace)
  (:export #:with-routes))
(in-package #:40ants-routes/with-routes)

;; Global variable to store current namespace
(defvar *current-namespace* nil
  "Current namespace for route resolution.")

;; Context management
(defmacro with-routes ((routes) &body body)
  "Execute body with the namespace from the given routes object as the current namespace."
  `(let ((*current-namespace* (collection-namespace ,routes)))
     ,@body))
