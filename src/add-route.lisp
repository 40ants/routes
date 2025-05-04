(uiop:define-package #:40ants-routes/add-route
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:has-namespace-p
                #:node-namespace
                #:url-path
                #:add-route)
  (:import-from #:40ants-routes/routes
                #:children-routes
                #:routes)
  (:import-from #:40ants-routes/route
                #:routep
                #:route)
  (:import-from #:40ants-routes/defroutes
                #:include)
  (:import-from #:40ants-routes/included-routes
                #:included-routes)
  (:import-from #:40ants-routes/errors
                #:path-duplication-error
                #:namespace-duplication-error)
  (:import-from #:serapeum
                #:soft-list-of
                #:->)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-equal
                #:url-pattern))
(in-package #:40ants-routes/add-route)


(-> search-route-with-path ((soft-list-of (or route
                                              included-routes))
                            url-pattern)
    (values (or null
                route
                included-routes)
            &optional))

(defun search-route-with-path (children path)
  (find path children
        :key #'url-path
        :test #'url-pattern-equal))


(-> search-route-with-namespace ((soft-list-of (or route
                                                   included-routes))
                                 string)
    (values (or null
                route
                included-routes)
            &optional))

(defun search-route-with-namespace (children namespace)
  (when namespace
    (loop for existing-route in children
          when (and (has-namespace-p existing-route)
                    (string= (node-namespace existing-route)
                             namespace))
            do (return existing-route))))


(defmethod add-route ((routes routes) (route route) &key override)
  "Add a route to the routes collection at runtime.
If a route with the same path already exists, an error will be signaled
unless override is set to true."
  (let* ((children (children-routes routes))
         (path (url-path route))
         (duplicate-route
           (search-route-with-path children path)))
    
    ;; Check for path duplication
    ;; (loop for existing-route in children
    ;;       when (and (routep existing-route)
    ;;                 ;; TODO: vожет убрать princ-to-string?
    ;;                 ;; заменить на url-pattern-pattern
    ;;                 (equal (princ-to-string (url-path existing-route))
    ;;                        (princ-to-string path)))
    ;;         do (setf duplicate-route existing-route)
    ;;            (return))
    
    (cond
      ;; If duplicate found and override is true, remove the old route
      ((and duplicate-route override)
       (setf (children-routes routes) 
             (cons route (remove duplicate-route children))))
      
      ;; If duplicate found and override is false, signal an error
      (duplicate-route
       (error 'path-duplication-error
              :existing-route duplicate-route
              :new-route route
              :path path))
      
      ;; No duplicate found, just add the route
      (t
       (setf (children-routes routes)
             (cons route children))))
    
    route))


(defmethod add-route ((routes routes) (routes-to-add routes) &key override)
  "We only allow to include objects of ROUTE or INCLUDED-ROUTES type.

   Thus we should wrap ROUTES with INCLUDED-ROUTES and path /"
  (add-route routes
             (include routes-to-add)
             :override override))


(defmethod add-route ((routes routes) (route included-routes) &key override)
  "Add any other type of object to the routes collection at runtime.
If the object has a namespace and a route with the same namespace already exists,
an error will be signaled unless override is true."
  (let* ((children (children-routes routes))
         (namespace (node-namespace route))
         (duplicate-by-path-route
           (search-route-with-path children (url-path route)))
         (duplicate-by-namespace-route
           (search-route-with-namespace children namespace)))

    (cond
      ;; If duplicate found and override is true, remove the old route and add the new one
      ((and (or duplicate-by-path-route
                duplicate-by-namespace-route)
            override)
       ;; Directly set the slot value to bypass the :around method
       (setf (children-routes routes)
             (cons route
                   (remove-if (lambda (item)
                                (or (eql duplicate-by-path-route
                                         item)
                                    (eql duplicate-by-namespace-route
                                         item)))
                              (children-routes routes)))))
      
      ;; If duplicate found and override is false, signal an error
      (duplicate-by-namespace-route
       (error 'namespace-duplication-error
              :existing-route duplicate-by-namespace-route
              :new-route route
              :namespace namespace))
      (duplicate-by-path-route
       (error 'path-duplication-error
              :existing-route duplicate-by-path-route
              :new-route route
              :path namespace))
      
      ;; No duplicate found, just add the route
      (t
       (setf (children-routes routes)
             (cons route children))))
    
    route))
