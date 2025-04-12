(uiop:define-package #:40ants-routes/with-routes
  (:use #:cl)
  (:import-from #:40ants-routes/find-route
                #:namespaces-chain)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*
                #:*current-routes*)
  (:export #:with-routes))
(in-package #:40ants-routes/with-routes)


;; Context management
(defmacro with-routes ((routes) &body body)
  "Execute body with the given routes object as the current routes context."
  (let ((routes-var (gensym "ROUTES")))
    `(let* ((,routes-var ,routes)
            (*current-namespace* (namespaces-chain ,routes-var))
            (*current-routes* ,routes-var))
       ,@body)))
