(uiop:define-package #:40ants-routes/defroutes
  (:use #:cl)
  (:import-from #:40ants-routes/route
                #:route)
  (:import-from #:40ants-routes/routes
                #:routes
                #:children-routes)
  (:import-from #:40ants-routes/included-routes
                #:included-routes)
  (:import-from #:40ants-routes/url-pattern
                #:url-pattern-params
                #:parse-url-pattern)
  (:import-from #:serapeum
                #:->
                #:fmt
                #:eval-always)
  (:import-from #:alexandria
                #:length=)
  (:shadow #:get
           #:delete)
  (:export #:defroutes
           #:url
           #:get
           #:post
           #:put
           #:include
           #:routes))
(in-package #:40ants-routes/defroutes)


(defmacro defroutes ((var-name &key namespace)
                     &body route-definitions)
  "Define a variable holding collection of routes."
  (unless namespace
    (error "NAMESPACE is required argument."))
     
  (unless (and (typep namespace 'string)
               (not (length= 0 namespace)))
    (error "NAMESPACE should be a non-empty string."))
  
  `(eval-always 
     (defvar ,var-name (make-instance 'routes
                                      :namespace ,namespace))

     ;; In case if we did change route on var redifinition
     (setf (40ants-routes/routes:routes-namespace ,var-name)
           ,namespace)
     
     (setf (children-routes ,var-name)
           (list ,@route-definitions))
     ,var-name))


(defmacro routes ((namespace)
                  &body route-definitions)
  "Define a variable holding collection of routes."
  (unless (and (typep namespace 'string)
               (not (length= 0 namespace)))
    (error "NAMESPACE should be a non-empty string."))

  (alexandria:with-gensyms (var-name)
    `(let ((,var-name
             (make-instance 'routes
                            :namespace ,namespace)))
       (setf (children-routes ,var-name)
             (list ,@route-definitions))
       ,var-name)))


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
      `(flet ((handler (&key ,@(loop for (param-name . param-type) in (url-pattern-params url-pattern)
                                     collect (intern (string-upcase param-name))))
                ,handler-docstring

                ,@(if handler-body
                      handler-body
                      '((values)))))
         ;; Here we have to call parse-url-pattern second time,
         ;; because first time was required for building the handler's arg list
         ;; during macro-expansion time:
         (let ((url-pattern
                 (parse-url-pattern ,path)))
           (make-instance 'route
                          :name ,name
                          :title ,title
                          :method ,http-method
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


(-> include (routes &key (:path string))
    (values included-routes))

(defun include (routes &key (path "/"))
  (let ((path (str:ensure-prefix
               "/"
               (str:ensure-suffix "/" path))))
    (make-instance 'included-routes
                   :original-collection routes
                   :path (parse-url-pattern path))))
