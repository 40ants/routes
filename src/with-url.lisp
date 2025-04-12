(uiop:define-package #:40ants-routes/with-url
  (:use #:cl)
  (:import-from #:serapeum
                #:->)
  (:import-from #:40ants-routes/route-collection
                #:route-collection)
  (:import-from #:40ants-routes/route
                #:route)
  (:import-from #:40ants-routes/included-route
                #:included-route))
(in-package #:40ants-routes/with-url)


(-> find-route-for-url ((or route-collection
                            route
                            included-route)
                        string)
    (values (or route
                included-route)
            &optional))

(defun find-route-for-url (routes url)
  "Searches a route matching URL.

   URL can match some nested route."
  ;; (declare (ignore url))
  (40ants-routes/generics::match-url routes url)
  ;; (etypecase routes
  ;;   (route routes)
  ;;   (included-route routes)
  ;;   (route-collection
  ;;    (loop for subroute in (40ants-routes/route-collection::collection-routes routes))))
  )



(defmacro with-url ((root-routes url) &body body)
  "Execute body with the current routes object corresponding to a given URL argument."
  (let ((root-routes-var (gensym "ROOT-ROUTES")))
    `(let* ((,root-routes-var ,root-routes)
            ;; (*current-namespace* (namespaces-chain ,routes-var))
            (*current-routes* (find-route-for-url ,root-routes-var
                                                  ,url)))
       ,@body)))
