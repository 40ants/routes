(uiop:define-package #:40ants-routes/vars
  (:use #:cl)
  (:import-from #:serapeum
                #:defvar-unbound))
(in-package #:40ants-routes/vars)



(defvar-unbound *current-namespace*
  "Current namespace for route resolution.")


(defvar-unbound *current-routes*
  "Current route collection for route resolution.")


(defvar-unbound *routes-path*
  "This variable will be bound during WITH-URL macro body execution.

   It contains a chain of routes matched to the given url.

   For example if we call WITH-URL on /company/blog/post-slug, then
   in the *ROUTES-PATH* will be three items:

   ```
   (lisp (ROUTE /post-slug)
         (INCLUDED-ROUTES /blog/)
         (INCLUDED-ROUTES /company/))
   ```")

