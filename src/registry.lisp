(uiop:define-package #:40ants-routes/registry
  (:use #:cl)
  (:import-from #:40ants-routes/with-routes
                #:*route-collections*
                #:find-collection-by-namespace)
  (:export))
(in-package #:40ants-routes/registry)

;; This file is kept for backward compatibility
;; The registry functionality has been moved to with-routes.lisp
