(uiop:define-package #:40ants-routes/core
  (:use #:cl)
  (:nicknames #:40ants-routes)
  (:use-reexport #:40ants-routes/route
                 #:40ants-routes/route-collection
                 #:40ants-routes/included-route
                 #:40ants-routes/url-pattern
                 #:40ants-routes/with-routes
                 #:40ants-routes/registry
                 #:40ants-routes/find-route
                 #:40ants-routes/defroutes
                 #:40ants-routes/route-url
                 #:40ants-routes/breadcrumbs))
(in-package #:40ants-routes/core)

;; This file serves as the main entry point for the library
;; All functionality is implemented in the other files
