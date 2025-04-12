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
                #:url-pattern-params
                #:parse-url-pattern)
  (:import-from #:serapeum
                #:->
                #:fmt
                #:eval-always)
  (:shadow #:get
           #:delete)
  (:export #:defroutes
           #:url
           #:get
           #:post
           #:put
           #:include))
(in-package #:40ants-routes/defroutes)


(defmacro defroutes ((var-name) &body route-definitions)
  "Define a variable holding collection of routes."
  `(eval-always
     (defvar ,var-name (make-instance 'route-collection))
     
     (setf (collection-routes ,var-name)
           (list ,@route-definitions))
     ,var-name))


(eval-always
  (defun generate-route (http-method path name title handler-body)
    (let ((url-pattern (parse-url-pattern path))
          (handler-docstring
            (fmt "Handler for ~S ~S"
                 http-method
                 path))
          (name (or name
                    (string-downcase
                     (gensym "UNNAMED-ROUTE-")))))
      `(flet ((handler ,(loop for (param-name . param-type) in (url-pattern-params url-pattern)
                              collect (intern (string-upcase param-name)))
                ,handler-docstring
                ,@handler-body))
         ;; Here we have to call parse-url-pattern second time,
         ;; because first time was required for building the handler's arg list
         ;; during macro-expansion time:
         (let ((url-pattern
                 (parse-url-pattern ,path)))
           (make-instance 'route
                          :name ,name
                          :title ,title
                          :pattern url-pattern
                          :handler #'handler))))))


(defmacro get ((path &key name title) &body handler-body)
  (generate-route :get path name title handler-body))

(defmacro post ((path &key name title) &body handler-body)
  (generate-route :post path name title handler-body))

(defmacro put ((path &key name title) &body handler-body)
  (generate-route :put path name title handler-body))

(defmacro delete ((path &key name title) &body handler-body)
  (generate-route :delete path name title handler-body))


(-> include (route-collection &key (:path string) (:namespace string))
    (values included-route))

(defun include (routes &key (path "/") namespace)
  (let ((path (str:ensure-prefix
               "/"
               (str:ensure-suffix "/" path))))
    (make-instance 'included-route
                   :original-collection routes
                   :path (parse-url-pattern path)
                   :namespace namespace)))

;; (defmacro get ((path &key name title) &body handler-body)
;;   (let ((url-pattern (parse-url-pattern path))
;;         (handler-docstring
;;           (fmt "Handler for GET ~S" path))
;;         (name (or name
;;                   (string-downcase
;;                    (gensym "UNNAMED-ROUTE-")))))
;;     `(flet ((handler ,(loop for (param-name . param-type) in (url-pattern-params url-pattern)
;;                             collect (intern (string-upcase param-name)))
;;               ,handler-docstring
;;               ,@handler-body))
;;        ;; Here we have to call parse-url-pattern second time,
;;        ;; because first time was required for building the handler's arg list
;;        ;; during macro-expansion time:
;;        (let ((url-pattern
;;                (parse-url-pattern ,path)))
;;          (make-instance 'route
;;                         :name ,name
;;                         :title ,title
;;                         :pattern url-pattern
;;                         :handler #'handler)))))


;; (get ("/foo/<string:name>")
;;   (format t "Foo called"))

;; (defun process-route-definition (definition namespace collection)
;;   "Process a route definition and create a route object."
;;   (cond
;;     ;; Legacy URL format
;;     ((and (listp definition) (eq (first definition) 'url))
;;      (destructuring-bind (url-pattern &rest options) (second definition)
;;        (let ((name (getf options :name))
;;              (title (getf options :title)))
;;          (unless name
;;            (error "Route must have a name: ~A" definition))
          
;;          (multiple-value-bind (regex-pattern params)
;;              (parse-url-pattern url-pattern)
;;            (make-instance 'route
;;                           :name name
;;                           :pattern regex-pattern
;;                           :parameters params
;;                           ;; :namespace namespace
;;                           :title title
;;                           :method :get
;;                           :handler `(lambda ,(mapcar #'car params)
;;                                       ,@(cddr definition)))))))
     
;;     ;; HTTP method formats (GET, POST, PUT)
;;     ((and (listp definition)
;;           (member (first definition) '(get post put) :test #'eq))
;;      (let ((method (first definition)))
;;        (destructuring-bind (url-pattern &rest options) (second definition)
;;          (let ((name (getf options :name))
;;                (title (getf options :title)))
;;            (unless name
;;              (error "Route must have a name: ~A" definition))
            
;;            (multiple-value-bind (regex-pattern params)
;;                (parse-url-pattern url-pattern)
;;              (make-instance 'route
;;                             :name name
;;                             :pattern regex-pattern
;;                             :parameters params
;;                             ;; :namespace namespace
;;                             :title title
;;                             :method (intern (string-upcase (symbol-name method)) :keyword)
;;                             :handler `(lambda ,(mapcar #'car params)
;;                                         ,@(cddr definition))))))))
     
;;     ;; Include other route collections
;;     ((and (listp definition) (eq (first definition) 'include))
;;      (let* ((original-collection (eval (second definition)))
;;             (options (cddr definition))
;;             (path (getf options :path ""))
;;             (parsed-path (parse-url-pattern path))
;;             ;; (namespace (getf options :namespace nil))
;;             )
;;        (make-instance 'included-route
;;                       :original-collection original-collection
;;                       :parent collection
;;                       :path parsed-path
;;                       :namespace namespace)))
    
;;     ;; Nested defroutes
;;     ;; ((and (listp definition) (eq (first definition) 'defroutes))
;;     ;;  (destructuring-bind (var-name &key namespace) (second definition)
;;     ;;    (let ((nested-collection (make-instance 'route-collection
;;     ;;                                            ;; :namespace namespace
;;     ;;                                            )))
;;     ;;      ;; Process the nested routes
;;     ;;      (setf (collection-routes nested-collection)
;;     ;;            (loop for def in (cddr definition)
;;     ;;                  collect (process-route-definition def namespace nested-collection)))
         
;;     ;;      ;; Set the variable to the collection
;;     ;;      (set var-name nested-collection)
;;     ;;      ;; Return an included-route that includes this collection
;;     ;;      (break)
;;     ;;      (make-instance 'included-route
;;     ;;                     :original-collection nested-collection
;;     ;;                     :parent collection
;;     ;;                     :path (parse-url-pattern "")
;;     ;;                     :namespace namespace))))
     
;;     (t (error "Unknown route definition: ~A" definition))))
