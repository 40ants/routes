(uiop:define-package #:40ants-routes/find-route
  (:use #:cl)
  (:import-from #:40ants-routes/with-routes
                #:*current-routes*
                #:with-routes)
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

;; Define find-route as a generic function
(defgeneric find-route (name namespace)
  (:documentation "Find a route by name in the given namespace hierarchy."))

;; Primary method for find-route
(defmethod find-route (name namespace)
  (unless *current-routes*
    (error "Use WITH-ROUTES macro to set current routes object."))
  
  (or
   ;; First, try to find the route directly in the collection's routes
   (when (or (null namespace)
             (string= (collection-namespace *current-routes*)
                      namespace))
     (find name (collection-routes *current-routes*)
           :key #'route-name
           :test #'string=))
   
   ;; Next, check if any of the routes is an included-route
   (loop for route in (collection-routes *current-routes*)
         when (typep route 'included-route)
           do (let* ((included-namespace (40ants-routes/included-route:included-route-namespace route))
                     (original-collection (included-route-original-collection route))
                     (found-route (if included-namespace
                                      ;; If the included route has a custom namespace, look for the route in that namespace
                                      (find-route name included-namespace)
                                      ;; Otherwise, look in the original collection
                                      (find name (collection-routes original-collection)
                                            :key #'route-name
                                            :test #'string=))))
                (when found-route
                  (return found-route))))
   
   ;; If not found in this namespace, check if this namespace is included in another namespace
   ;; and look for the route there with the original name
   (loop for parent-ns being the hash-keys of *route-collections*
           using (hash-value parent-collection)
         do (with-routes (parent-collection)
              (loop for route in (collection-routes *current-routes*)
                    when (and (typep route 'included-route)
                              (let ((included-ns (40ants-routes/included-route:included-route-namespace route)))
                                (and included-ns (string= included-ns namespace))))
                      do (let ((found-route (find name (collection-routes (included-route-original-collection route))
                                                  :key #'route-name
                                                  :test #'string=)))
                           (when found-route
                             (return-from find-route found-route))))))))

;; Special case for entity routes included with custom namespaces
(defmethod find-route :around ((name string) (namespace string))
  (call-next-method)
  ;; (if (or (string= namespace "users") (string= namespace "posts"))
  ;;     ;; For users and posts namespaces, look in the entity routes
  ;;     (let ((entity-routes (gethash "entity" *route-collections*)))
  ;;       (when entity-routes
  ;;         (with-routes (entity-routes)
  ;;           (let ((found-route (find name (collection-routes *current-routes*)
  ;;                                    :key #'route-name
  ;;                                    :test #'string=)))
  ;;             (if found-route
  ;;                 found-route
  ;;                 (call-next-method))))))
  ;;     (call-next-method))
  )

(defun find-matching-route (url)
  "Find a route that matches the given URL."
  (error "Remake without route-collections")
  ;; (let ((parts (split-sequence #\/ url :remove-empty-subseqs t)))
  ;;   (cond
  ;;     ((null parts)
  ;;      ;; Root URL - find the app index route
  ;;      (let ((result nil)
  ;;            (app-routes (gethash "app" *route-collections*)))
  ;;        (when app-routes
  ;;          (with-routes (app-routes)
  ;;            (let ((routes (collection-routes *current-routes*)))
  ;;              (setf result (find-if (lambda (r)
  ;;                                      (and (string= (route-name r) "index")
  ;;                                           (string= (route-namespace r) "app")))
  ;;                                    routes)))))
  ;;        result))
  ;;     (t
  ;;      ;; Non-root URL - find a route in the namespace
  ;;      (let* ((namespace (first parts))
  ;;             (result nil)
  ;;             (namespace-routes (gethash namespace *route-collections*)))
  ;;        (when namespace-routes
  ;;          (with-routes (namespace-routes)
  ;;            (let ((routes (collection-routes *current-routes*)))
  ;;              (setf result (find-if (lambda (r)
  ;;                                      (match-url r url))
  ;;                                    routes)))))
  ;;        result))))
  )
