(uiop:define-package #:40ants-routes/find-route
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*routes-path*)
  (:import-from #:40ants-routes/route
                #:routep
                #:route
                #:route-name)
  (:import-from #:40ants-routes/routes
                #:routesp
                #:routes
                #:children-routes)
  (:import-from #:40ants-routes/included-routes
                #:included-routes-p
                #:included-routes
                #:original-routes)
  (:import-from #:split-sequence
                #:split-sequence)
  (:import-from #:40ants-routes/url-pattern
                #:match-url)
  (:import-from #:serapeum
                #:length<=
                #:soft-list-of
                #:->)
  (:import-from #:alexandria
                #:last-elt)
  (:import-from #:40ants-routes/generics
                #:node-namespace)
  (:export #:find-route))
(in-package #:40ants-routes/find-route)


(-> absolute-namespace-p (t)
    (values boolean &optional))

(defun absolute-namespace-p (namespace)
  (and (typep namespace 'list)
       (length<= 2 namespace)
       (eql (first namespace)
            :absolute)))


(-> search-routes-with-namespace ((or routes included-routes)
                                  list
                                  &key (:on-match (or null function)))
    (values (or null
                routes
                included-routes)
            &optional))

(defun search-routes-with-namespace (root-routes namespaces &key on-match)
  "If given, ON-MATCH callable will be called starting from the root node to the last routes object matching the last namespace in the list."
  (labels ((recursive-search (routes namespaces path)
             (let ((namespace-to-search (first namespaces)))
               (cond
                 ((included-routes-p routes)
                  (recursive-search (original-routes routes)
                                    namespaces
                                    (cons routes
                                          path)))
                 ((string= namespace-to-search
                           (node-namespace routes))
                  (let ((rest-namespaces (rest namespaces)))
                    (cond
                      (rest-namespaces
                       (loop for child in (children-routes routes)
                             thereis (unless (routep child)
                                       (recursive-search child
                                                         rest-namespaces
                                                         (cons routes path)))))
                      ;; We've found our routes object
                      (t
                       (when on-match
                         (mapc on-match
                               (nreverse path))
                         (funcall on-match
                                  routes))
                       (values routes)))))))))
    (recursive-search root-routes
                      namespaces
                      nil)))


(-> search-child-route-with-name ((or routes
                                      included-routes)
                                  string)
    (values (or null
                route)))

(defun search-child-route-with-name (routes name)
  (loop for route in (40ants-routes/routes::children-routes routes)
        for route-name = (when (routep route)
                           (40ants-routes/route::route-name route))
        when (string= route-name
                      name)
          do (return route)))


(-> find-route (string
                &key
                (:namespace list)
                (:on-match (or null function)))
    (values (or null
                route)
            &optional))

(defun find-route (name &key namespace on-match)
  "Find a route by name in the given namespace hierarchy.

   If route was found, then returns it.

   Additionally, it will call ON-MATCH callable argument
   with each route node along path to the leaf route."
  (unless *routes-path*
    (error "Use WITH-URL macro to set current routes object."))

  ;; Here we have two scenerios:
  ;; 
  ;; 1. namespace is not given
  ;; 2. namespace is given in form (:absolute "foo" "bar" ...)

  (let ((result
          (cond
            ((null namespace)
             ;; This is a simplest case, we have to get parent of the current route
             ;; from *routes-path* and search route with the given name among it's
             ;; children:
             (let ((parent (second *routes-path*)))
               (search-child-route-with-name parent name)))
            ;; If absolute namespace was given, then we take the root route
            ;; and start searching down the tree:
            (namespace
             (let* ((root (last-elt *routes-path*))
                    (routes (search-routes-with-namespace root namespace
                             :on-match on-match)))
               (when routes
                 (search-child-route-with-name routes name)))))))
    (when (and result
               on-match)
      (funcall on-match result))
    (values result)))

