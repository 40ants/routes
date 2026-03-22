(uiop:define-package #:40ants-routes-docs/changelog
  (:use #:cl)
  (:import-from #:40ants-doc/changelog
                #:defchangelog))
(in-package #:40ants-routes-docs/changelog)


(defchangelog (:ignore-words ("URL"
                              "ASDF"
                              "HTTP"))
  (0.5.0 2026-03-21
         "Changes:
          * Added 40ANTS-ROUTES/DEFROUTES:EXTEND-ROUTES macro to extend a routes collection bound to a variable without creating a new collection")
  (0.4.1 2026-03-21
         "Duplicate breadcrumbs, returned by 40ANTS-ROUTES/BREADCRUMBS:GET-BREADCRUMBS were fixed.")
  (0.4.0 2025-05-04
         "First public release.")
  (0.3.0 2025-04-06
         "Changes:
          * Renamed `with-routes-context` to `with-routes` and modified it to take a routes object as an argument instead of a namespace string
          * Refactored the codebase by splitting `core.lisp` into multiple files for better organization and maintainability")
  
  (0.2.0 2025-04-06
         "Changes:

          * Modified `include` to create an `included-route` proxy object instead of modifying the parent of the included collection
          * Added `included-route-original-collection` accessor to get the original collection from an included route
          * Removed the `parent` slot from the `route-collection` class as it's no longer needed")
  
  (0.1.0 2024-04-05
         "Initial version:

          * Define routes with namespaces
          * Include routes from libraries into applications
          * Generate URLs based on route names
          * Handle URL parameters
          * Generate breadcrumbs
          * Support for different types of routes (server, application, library)"))
