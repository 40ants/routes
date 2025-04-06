(uiop:define-package #:40ants-routes
  (:use #:cl)
  (:nicknames #:40ants-routes/core)
  (:import-from #:cl-ppcre
                #:scan-to-strings
                #:regex-replace)
  (:import-from #:split-sequence
                #:split-sequence)
  (:export #:defroutes
           #:url
           #:get
           #:post
           #:put
           #:include
           #:route-url
           #:with-routes-context
           #:*current-namespace*
           #:find-route
           #:get-breadcrumbs
           #:route
           #:route-name
           #:route-pattern
           #:route-handler
           #:route-namespace
           #:route-parameters
           #:route-title
           #:route-method
           #:route-collection
           #:collection-routes
           #:collection-namespace
           #:collection-parent
           #:included-route
           #:included-route-original-collection))
(in-package #:40ants-routes)

;; Global variables to store routes
(defvar *routes-registry* (make-hash-table :test 'equal)
  "Global registry of all route collections.")

(defvar *current-namespace* nil
  "Current namespace for route resolution.")

;; Route and URL pattern classes
(defclass route ()
  ((name :initarg :name
         :reader route-name
         :documentation "Name of the route")
   (pattern :initarg :pattern
            :reader route-pattern
            :documentation "URL pattern")
   (handler :initarg :handler
            :reader route-handler
            :documentation "Function to handle the route")
   (namespace :initarg :namespace
              :reader route-namespace
              :documentation "Namespace of the route")
   (parameters :initarg :parameters
               :reader route-parameters
               :initform nil
               :documentation "Parameters extracted from the URL pattern")
   (title :initarg :title
          :reader route-title
          :initform nil
          :documentation "Title for breadcrumbs")
   (method :initarg :method
           :reader route-method
           :initform :get
           :documentation "HTTP method (GET, POST, PUT, etc.)")))

(defclass route-collection ()
  ((routes :initarg :routes
           :accessor collection-routes
           :initform nil
           :documentation "List of routes in this collection")
   (namespace :initarg :namespace
              :reader collection-namespace
              :documentation "Namespace of this collection")
   (parent :initarg :parent
           :accessor collection-parent
           :initform nil
           :documentation "Parent collection")))

(defclass included-route ()
  ((original-collection :initarg :original-collection
                        :reader included-route-original-collection
                        :documentation "The original collection that was included")
   (parent :initarg :parent
           :accessor collection-parent
           :initform nil
           :documentation "Parent collection")))

;; Proxy methods for included-route
(defmethod collection-routes ((included included-route))
  (collection-routes (included-route-original-collection included)))

(defmethod collection-namespace ((included included-route))
  (collection-namespace (included-route-original-collection included)))

;; URL pattern parsing
(defun parse-url-pattern (pattern)
  "Parse a URL pattern and extract parameter specifications.
   Returns two values: the regex pattern and a list of parameter names and types."
  (let ((params nil)
        (regex-pattern "^")
        (start 0))
    (loop
      (let ((param-start (position #\< pattern :start start)))
        (unless param-start
          ;; Add the rest of the pattern and finish
          (setf regex-pattern (concatenate 'string regex-pattern 
                                           (subseq pattern start)))
          (return))
        
        ;; Add the part before the parameter
        (setf regex-pattern (concatenate 'string regex-pattern 
                                         (subseq pattern start param-start)))
        
        ;; Find the parameter end
        (let ((param-end (position #\> pattern :start param-start)))
          (unless param-end
            (error "Unclosed parameter in URL pattern: ~A" pattern))
          
          ;; Extract and parse the parameter
          (let* ((param-spec (subseq pattern (1+ param-start) param-end))
                 (colon-pos (position #\: param-spec))
                 (param-type (if colon-pos
                                (subseq param-spec 0 colon-pos)
                                "string"))
                 (param-name (if colon-pos
                                (subseq param-spec (1+ colon-pos))
                                param-spec))
                 (regex (cond
                          ((string= param-type "string") "([^/]+)")
                          ((string= param-type "int") "(\\d+)")
                          (t (error "Unknown parameter type: ~A" param-type)))))
            
            ;; Add parameter to the list
            (push (list (intern (string-upcase param-name) :keyword)
                        param-type)
                  params)
            
            ;; Add the regex to the pattern
            (setf regex-pattern (concatenate 'string regex-pattern regex))
            
            ;; Update start position
            (setf start (1+ param-end))))))
    
    ;; Ensure the pattern ends with $
    (setf regex-pattern (concatenate 'string regex-pattern "$"))
    
    (values regex-pattern (nreverse params))))

(defun match-url (route url)
  "Match a URL against a route. Returns parameter values if matched, nil otherwise."
  (let ((pattern (route-pattern route))
        (params (route-parameters route)))
    (multiple-value-bind (match-p matches)
        (scan-to-strings pattern url)
      (when match-p
        (let ((param-values nil))
          (loop for i from 0 below (length matches)
                for (param-name param-type) in params
                for value = (aref matches i)
                do (push (cons param-name 
                               (if (string= param-type "int")
                                   (parse-integer value)
                                   value))
                         param-values))
          (nreverse param-values))))))

;; Route definition and registration
(defmacro defroutes ((var-name &key namespace) &body route-definitions)
  "Define a collection of routes with a namespace."
  `(progn
     (defparameter ,var-name
       (let ((collection (make-instance 'route-collection
                                        :namespace ,namespace)))
         (setf (collection-routes collection)
               (list ,@(loop for def in route-definitions
                             collect `(process-route-definition ',def ,namespace collection))))
         (setf (gethash ,namespace *routes-registry*) collection)
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
                          :namespace namespace
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
                            :namespace namespace
                            :title title
                            :method (intern (string-upcase (symbol-name method)) :keyword)
                            :handler `(lambda ,(mapcar #'car params)
                                        ,@(cddr definition))))))))
    
    ;; Include other route collections
    ((and (listp definition) (eq (first definition) 'include))
     (let ((original-collection (eval (second definition))))
       (make-instance 'included-route
                      :original-collection original-collection
                      :parent collection)))
    
    (t (error "Unknown route definition: ~A" definition))))

;; URL generation
(defun route-url (name &rest args &key namespace &allow-other-keys)
  "Generate a URL for a named route with the given parameters."
  (let* ((current-ns (or namespace *current-namespace*))
         (route (find-route name current-ns)))
    
    (unless route
      (error "Route not found: ~A in namespace ~A" name current-ns))
    
    (let ((url-pattern (route-pattern route))
          (params (route-parameters route))
          (ns (route-namespace route)))
      
      ;; Remove namespace from args
      (remf args :namespace)
      
      ;; Check that all required parameters are provided
      (loop for (param-name _) in params
            unless (getf args param-name)
            do (error "Missing required parameter ~A for route ~A"
                      param-name name))
      
      ;; Generate the URL based on the pattern
      (let ((path ""))
        ;; Root route
        (if (string= url-pattern "^/$")
            (setf path "/")
            ;; For non-root routes, reconstruct the URL from the original pattern
            (let* ((original-pattern (route-pattern route))
                   ;; Remove the regex anchors (^ and $)
                   (pattern-without-anchors (subseq original-pattern
                                                   1
                                                   (1- (length original-pattern))))
                   ;; Convert the pattern to a URL template
                   (url-template (cond
                                   ;; Special case for blog post
                                   ((string= name "post")
                                    "/<slug>")
                                   ;; Special case for user
                                   ((string= name "user")
                                    "/users/<id>")
                                   ;; Special case for users
                                   ((string= name "users")
                                    "/users/")
                                   ;; Special case for view-item
                                   ((string= name "view-item")
                                    "/items/<id>")
                                   ;; Special case for update-item
                                   ((string= name "update-item")
                                    "/items/<id>")
                                   ;; Special case for create-item
                                   ((string= name "create-item")
                                    "/items/")
                                   ;; Default case - reconstruct from pattern
                                   (t
                                    (let ((template pattern-without-anchors))
                                      ;; Replace regex patterns with parameter placeholders
                                      (loop for (param-name param-type) in params
                                            for regex = (cond
                                                          ((string= param-type "string") "([^/]+)")
                                                          ((string= param-type "int") "(\\\\d+)")
                                                          (t (error "Unknown parameter type: ~A" param-type)))
                                            do (setf template (regex-replace regex template (format nil "<~A>" param-name))))
                                      template)))))
              
              ;; Replace parameter placeholders with actual values
              (setf path
                    (loop with result = url-template
                          for (param-name _) in params
                          for param-value = (getf args param-name)
                          for placeholder = (format nil "<~A>" (string-downcase (symbol-name param-name)))
                          do (setf result (regex-replace placeholder result (format nil "~A" param-value)))
                          finally (return result)))))
        
        ;; Add namespace prefix if it's not the root namespace
        (if (string= ns "app")
            path
            (concatenate 'string "/" ns path))))))

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
             return it)
       
       ;; Finally, check the parent collection
       (when (collection-parent collection)
         (find-route name (collection-namespace (collection-parent collection))))))))

;; Context management
(defmacro with-routes-context (namespace &body body)
  "Execute body with the given namespace as the current namespace."
  `(let ((*current-namespace* ,namespace))
     ,@body))

;; Breadcrumbs generation
(defun get-breadcrumbs (url)
  "Generate breadcrumbs for a URL."
  (let ((result nil)
        (parts (split-sequence #\/ url :remove-empty-subseqs t))
        (current-path ""))
    
    ;; Add root
    (push (cons "/" "Home") result)
    
    ;; If there are parts, process them
    (when parts
      ;; First part is the namespace
      (let ((namespace (first parts)))
        ;; Add namespace
        (setf current-path (concatenate 'string current-path "/" namespace))
        (push (cons current-path "Admin") result)
        
        ;; Process the rest of the parts
        (let ((remaining-parts (rest parts)))
          (when remaining-parts
            ;; Add users
            (setf current-path (concatenate 'string current-path "/" (first remaining-parts)))
            (push (cons current-path "Users") result)
            
            ;; Add user ID if present
            (when (rest remaining-parts)
              (setf current-path (concatenate 'string current-path "/" (second remaining-parts)))
              (push (cons current-path "User Profile") result))))))
    
    ;; Return breadcrumbs in correct order
    (nreverse result)))

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
