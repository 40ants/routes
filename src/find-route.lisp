(uiop:define-package #:40ants-routes/find-route
  (:use #:cl)
  (:import-from #:40ants-routes/with-routes
                #:*current-routes*
                #:*route-collections*)
  (:import-from #:40ants-routes/route
                #:route-name
                #:route-namespace)
  (:import-from #:40ants-routes/route-collection
                #:collection-routes
                #:collection-namespace)
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
  (let ((routes-collection (gethash namespace *route-collections*)))
    (when routes-collection
      (with-routes (routes-collection)
        (or
         ;; First, try to find the route directly in the collection's routes
         (find name (collection-routes *current-routes*)
               :key #'route-name
               :test #'string=)
         
         ;; Next, check if any of the routes is an included-route
         (loop for route in (collection-routes *current-routes*)
               when (and (typep route 'included-route)
                         (find name (collection-routes (included-route-original-collection route))
                               :key #'route-name
                               :test #'string=))
               return it))))))

(defun find-matching-route (url)
  "Find a route that matches the given URL."
  (let ((parts (split-sequence #\/ url :remove-empty-subseqs t)))
    (cond
      ((null parts)
       ;; Root URL - find the app index route
       (let ((result nil)
             (app-routes (gethash "app" *route-collections*)))
         (when app-routes
           (with-routes (app-routes)
             (let ((routes (collection-routes *current-routes*)))
               (setf result (find-if (lambda (r)
                                       (and (string= (route-name r) "index")
                                            (string= (route-namespace r) "app")))
                                     routes)))))
         result))
      (t
       ;; Non-root URL - find a route in the namespace
       (let* ((namespace (first parts))
              (result nil)
              (namespace-routes (gethash namespace *route-collections*)))
         (when namespace-routes
           (with-routes (namespace-routes)
             (let ((routes (collection-routes *current-routes*)))
               (setf result (find-if (lambda (r)
                                       (match-url r url))
                                     routes)))))
         result)))))
