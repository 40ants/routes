(uiop:define-package #:40ants-routes/find-route
  (:use #:cl)
  (:import-from #:40ants-routes/registry
                #:*routes-registry*)
  (:import-from #:40ants-routes/route
                #:route-name)
  (:import-from #:40ants-routes/route-collection
                #:collection-routes)
  (:import-from #:40ants-routes/included-route
                #:included-route
                #:included-route-original-collection)
  (:import-from #:split-sequence
                #:split-sequence)
  (:import-from #:40ants-routes/url-pattern
                #:match-url)
  (:export #:find-route
           #:find-matching-route))
(in-package #:40ants-routes/find-route)

(defun find-route (name namespace)
  "Find a route by name in the given namespace hierarchy."
  (let ((collection (gethash namespace *routes-registry*)))
    (when collection
      (or
       ;; First, try to find the route directly in the collection's routes
       (find name (collection-routes collection)
             :key #'route-name
             :test #'string=)
       
       ;; Next, check if any of the routes is an included-route
       (loop for route in (collection-routes collection)
             when (and (typep route 'included-route)
                       (find name (collection-routes (included-route-original-collection route))
                             :key #'route-name
                             :test #'string=))
             return it)))))

(defun find-matching-route (url)
  "Find a route that matches the given URL."
  (let ((parts (split-sequence #\/ url :remove-empty-subseqs t)))
    (cond
      ((null parts)
       ;; Root URL - find the app index route
       (let ((result nil))
         (maphash (lambda (namespace collection)
                    (declare (ignore namespace))
                    (let ((routes (collection-routes collection))
                          (coll-namespace (collection-namespace collection)))
                      (when (string= coll-namespace "app")
                        (let ((route (find-if (lambda (r)
                                                (and (string= (route-name r) "index")
                                                     (string= (route-namespace r) "app")))
                                              routes)))
                          (when route
                            (setf result route))))))
                  *routes-registry*)
         result))
      (t
       ;; Non-root URL - find a route in the namespace
       (let ((namespace (first parts))
             (result nil))
         (maphash (lambda (ns collection)
                    (declare (ignore ns))
                    (let ((routes (collection-routes collection))
                          (coll-namespace (collection-namespace collection)))
                      (when (string= coll-namespace namespace)
                        (let ((route (find-if (lambda (r)
                                                (match-url r url))
                                              routes)))
                          (when route
                            (setf result route))))))
                  *routes-registry*)
         result)))))