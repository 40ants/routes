(uiop:define-package #:40ants-routes/find-route
  (:use #:cl)
  (:import-from #:40ants-routes/vars
                #:*routes-path*
                #:*current-routes*)
  (:import-from #:40ants-routes/route
                #:route
                #:route-name)
  (:import-from #:40ants-routes/routes
                #:routes
                #:children-routes
                #:collection-namespace)
  (:import-from #:40ants-routes/included-routes
                #:included-routes
                #:included-routes-original-collection)
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
  (:export #:find-route))
(in-package #:40ants-routes/find-route)


;; (-> namespaces-chain ((or included-routes
;;                           routes
;;                           route))
;;     (values (soft-list-of string) &optional))


;; (defun namespaces-chain (routes)
;;   (loop for current = routes
;;           then (cond
;;                  ((typep current 'included-routes)
;;                   (40ants-routes/included-routes:collection-parent current))
;;                  (t
;;                   nil))
;;         for current-namespace = (typecase current
;;                                   (included-routes
;;                                    (40ants-routes/included-routes::included-routes-namespace current))
;;                                   (t
;;                                    nil))
;;         while current-namespace
;;         collect current-namespace))


;; (-> ensure-absolute-namespace ((or string
;;                                    (soft-list-of string))
;;                                (or included-routes
;;                                    routes
;;                                    route))
;;     (values (soft-list-of string)
;;             &optional))

;; (defun ensure-absolute-namespace (namespace current-routes)
;;   (etypecase namespace
;;     (string
;;      (append (namespaces-chain current-routes)
;;              (list namespace)))
;;     (list
;;      (values namespace))))


(-> absolute-namespace-p (t)
    (values boolean &optional))

(defun absolute-namespace-p (namespace)
  (and (typep namespace 'list)
       (length<= 2 namespace)
       (eql (first namespace)
            :absolute)))


(-> search-routes-with-namespace ((or routes included-routes)
                                  list)
    (values (or null
                routes
                included-routes)
            &optional))

(defun search-routes-with-namespace (root-routes namespaces)
  (loop with namespace-to-search = (first namespaces)
        for child in (40ants-routes/routes::children-routes root-routes)
        when (and (40ants-routes/included-routes::included-routes-p child)
                  (string= (40ants-routes/included-routes::included-routes-namespace child)
                           namespace-to-search))
          do (return (let ((rest-namespaces (rest namespaces)))
                       (cond
                         (rest-namespaces
                          (search-routes-with-namespace child
                                                        rest-namespaces))
                         (t
                          child)))))
  
  ;; (typecase root-routes
  ;;   (routes
  ;;    (loop with namespace-to-search = (first namespaces)
  ;;          for child in (40ants-routes/routes::children-routes root-routes)
  ;;          when (and (40ants-routes/included-routes::included-routes-p child)
  ;;                    (string= (40ants-routes/included-routes::included-routes-namespace child)
  ;;                             namespace-to-search))
  ;;            do (return (let ((rest-namespaces (rest namespaces)))
  ;;                         (cond
  ;;                           (rest-namespaces
  ;;                            (search-routes-with-namespace child
  ;;                                                          rest-namespaces))
  ;;                           (t
  ;;                            child))))))
  ;;   (40ants-routes/included-routes::included-routes
  ;;    (search-routes-with-namespace (40ants-routes/included-routes::included-routes-original-collection root-routes)
  ;;                                  namespaces)))
  )


(-> search-child-route-with-name ((or routes
                                      included-routes)
                                  string)
    (values (or null
                route)))

(defun search-child-route-with-name (routes name)
  (loop for route in (40ants-routes/routes::children-routes routes)
        for route-name = (40ants-routes/route::route-name route)
        when (string= route-name
                      name)
          do (return route)))


(-> find-route (string &key (:namespace list))
    (values (or null
                route)
            &optional))

(defun find-route (name &key namespace)
  "Find a route by name in the given namespace hierarchy."
  (unless *routes-path*
    (error "Use WITH-URL macro to set current routes object."))

  ;; Here we have two scenerios:
  ;; 
  ;; 1. namespace is not given
  ;; 2. namespace is given in form (:absolute "foo" "bar" ...)

  (cond
    ((null namespace)
     ;; This is a simplest case, we have to get parent of the current route
     ;; from *routes-path* and search route with the given name among it's
     ;; children:
     (let* ((parent (second *routes-path*))
            ;; Just assert a precondition
            ;; (parent (etypecase parent
            ;;           (40ants-routes/included-routes:included-routes
            ;;            (40ants-routes/included-routes:included-routes-original-collection parent))
            ;;           (40ants-routes/routes::routes parent)))
            )
       (search-child-route-with-name parent name))
     )
    ;; If absolute namespace was given, then we take the root route
    ;; and start searching down the tree:
    ((absolute-namespace-p namespace)
     (let* ((root (last-elt *routes-path*))
            (routes (search-routes-with-namespace root (cdr namespace))))
       (when routes
         (search-child-route-with-name routes name))))
    (t
     (error "Namespace should be NIL or in form (:absolute \"foo\" \"bar\")."))))

