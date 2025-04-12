(uiop:define-package #:40ants-routes/defroutes
  (:use #:cl)
  (:import-from #:40ants-routes/route
                #:route)
  (:import-from #:40ants-routes/route-collection
                #:route-collection
                #:collection-routes)
  (:import-from #:40ants-routes/included-route
                #:included-route)
  (:import-from #:40ants-routes/url-pattern
                #:parse-url-pattern)
  (:export #:defroutes
           #:url
           #:get
           #:post
           #:put
           #:include))
(in-package #:40ants-routes/defroutes)

;; Route definition and registration
(defmacro defroutes ((var-name &key namespace) &body route-definitions)
  "Define a collection of routes with a namespace."
  `(progn
     (defparameter ,var-name
       (let ((collection (make-instance 'route-collection
                                        ;; :namespace ,namespace
                                        )))
         (setf (collection-routes collection)
               (list ,@(loop for def in route-definitions
                             collect `(process-route-definition ',def ,namespace collection))))
         collection))
     ,var-name))

(defun process-route-definition (definition namespace collection)
  "Process a route definition and create a route object."
  (cond
    ;; Legacy URL format
    ((and (listp definition) (eq (first definition) 'url))
     (destructuring-bind (url-pattern &rest options) (second definition)
       (let ((name (getf options :name))
             (title (getf options :title)))
         (unless name
           (error "Route must have a name: ~A" definition))
          
         (multiple-value-bind (regex-pattern params)
             (parse-url-pattern url-pattern)
           (make-instance 'route
                          :name name
                          :pattern regex-pattern
                          :parameters params
                          ;; :namespace namespace
                          :title title
                          :method :get
                          :handler `(lambda ,(mapcar #'car params)
                                      ,@(cddr definition)))))))
     
    ;; HTTP method formats (GET, POST, PUT)
    ((and (listp definition)
          (member (first definition) '(get post put) :test #'eq))
     (let ((method (first definition)))
       (destructuring-bind (url-pattern &rest options) (second definition)
         (let ((name (getf options :name))
               (title (getf options :title)))
           (unless name
             (error "Route must have a name: ~A" definition))
            
           (multiple-value-bind (regex-pattern params)
               (parse-url-pattern url-pattern)
             (make-instance 'route
                            :name name
                            :pattern regex-pattern
                            :parameters params
                            ;; :namespace namespace
                            :title title
                            :method (intern (string-upcase (symbol-name method)) :keyword)
                            :handler `(lambda ,(mapcar #'car params)
                                        ,@(cddr definition))))))))
     
    ;; Include other route collections
    ((and (listp definition) (eq (first definition) 'include))
     (let* ((original-collection (eval (second definition)))
            (options (cddr definition))
            (path (getf options :path ""))
            (parsed-path (parse-url-pattern path))
            ;; (namespace (getf options :namespace nil))
            )
       (make-instance 'included-route
                      :original-collection original-collection
                      :parent collection
                      :path parsed-path
                      :namespace namespace)))
    
    ;; Nested defroutes
    ;; ((and (listp definition) (eq (first definition) 'defroutes))
    ;;  (destructuring-bind (var-name &key namespace) (second definition)
    ;;    (let ((nested-collection (make-instance 'route-collection
    ;;                                            ;; :namespace namespace
    ;;                                            )))
    ;;      ;; Process the nested routes
    ;;      (setf (collection-routes nested-collection)
    ;;            (loop for def in (cddr definition)
    ;;                  collect (process-route-definition def namespace nested-collection)))
         
    ;;      ;; Set the variable to the collection
    ;;      (set var-name nested-collection)
    ;;      ;; Return an included-route that includes this collection
    ;;      (break)
    ;;      (make-instance 'included-route
    ;;                     :original-collection nested-collection
    ;;                     :parent collection
    ;;                     :path (parse-url-pattern "")
    ;;                     :namespace namespace))))
     
    (t (error "Unknown route definition: ~A" definition))))
