(uiop:define-package #:40ants-routes/route-name
  (:use #:cl)
  (:import-from #:40ants-routes/route
                #:route-name)
  (:import-from #:40ants-routes/routes
                #:routes)
  (:import-from #:40ants-routes/included-routes
                #:included-routes
                #:included-routes-original-collection
                #:included-routes-namespace))
(in-package #:40ants-routes/route-name)

;; Add a route-name method for routes
(defmethod route-name ((collection routes))
  "Get the name of a route collection, which is its namespace."
  (error "Should be removed"))


;; Add a route-name method for included-routes
(defmethod route-name ((included included-routes))
  "Get the name of an included route, which is the name of its original collection."
  (let ((custom-namespace (included-routes-namespace included)))
    (if custom-namespace
        custom-namespace
        (route-name (included-routes-original-collection included)))))
