(uiop:define-package #:40ants-routes/route-name
  (:use #:cl)
  (:import-from #:40ants-routes/route
                #:route-name)
  (:import-from #:40ants-routes/route-collection
                #:route-collection
                #:collection-namespace)
  (:import-from #:40ants-routes/included-route
                #:included-route
                #:included-route-original-collection
                #:included-route-namespace))
(in-package #:40ants-routes/route-name)

;; Add a route-name method for route-collection
(defmethod route-name ((collection route-collection))
  "Get the name of a route collection, which is its namespace."
  (collection-namespace collection))

;; Add a route-name method for included-route
(defmethod route-name ((included included-route))
  "Get the name of an included route, which is the name of its original collection."
  (let ((custom-namespace (included-route-namespace included)))
    (if custom-namespace
        custom-namespace
        (route-name (included-route-original-collection included)))))