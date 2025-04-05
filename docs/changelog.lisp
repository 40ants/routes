(uiop:define-package #:40ants-routes-docs/changelog
  (:use #:cl)
  (:import-from #:40ants-doc/changelog
                #:defchangelog))
(in-package #:40ants-routes-docs/changelog)


(defchangelog (:ignore-words ("URL"
                              "ASDF"
                              "HTTP"))
  (0.1.0 2023-04-05
         "Initial version:
          * Define routes with namespaces
          * Include routes from libraries into applications
          * Generate URLs based on route names
          * Handle URL parameters
          * Generate breadcrumbs
          * Support for different types of routes (server, application, library)"))
