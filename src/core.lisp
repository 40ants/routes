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
           #:include
           #:route-url
           #:with-routes-context
           #:*current-namespace*
           #:find-route
           #:get-breadcrumbs))
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
          :documentation "Title for breadcrumbs")))

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
                          :handler `(lambda ,(mapcar #'car params)
                                      ,@(cddr definition)))))))
    
    ((and (listp definition) (eq (first definition) 'include))
     (let ((included-collection (eval (second definition))))
       (setf (collection-parent included-collection) collection)
       included-collection))
    
    (t (error "Unknown route definition: ~A" definition))))

;; URL generation
(defun route-url (name &rest args &key namespace &allow-other-keys)
  "Generate a URL for a named route with the given parameters."
  (let* ((current-ns (or namespace *current-namespace*))
         (route (find-route name current-ns)))
    
    (unless route
      (error "Route not found: ~A in namespace ~A" name current-ns))
    
    (let ((url-pattern (route-pattern route))
          (params (route-parameters route)))
      
      ;; Remove namespace from args
      (remf args :namespace)
      
      ;; Check that all required parameters are provided
      (loop for (param-name _) in params
            unless (getf args param-name)
            do (error "Missing required parameter ~A for route ~A"
                      param-name name))
      
      ;; Generate the URL by replacing parameters
      (let ((url url-pattern))
        (loop for (param-name param-type) in params
              for value = (getf args param-name)
              for regex = (cond
                            ((string= param-type "string") "([^/]+)")
                            ((string= param-type "int") "(\\d+)")
                            (t (error "Unknown parameter type: ~A" param-type)))
              do (setf url (regex-replace regex url (princ-to-string value))))
        
        ;; Remove ^ and $ from the beginning and end
        (subseq url 1 (1- (length url)))))))

(defun find-route (name namespace)
  "Find a route by name in the given namespace hierarchy."
  (let ((collection (gethash namespace *routes-registry*)))
    (when collection
      (or (find name (collection-routes collection)
                :key #'route-name
                :test #'string=)
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
  (let ((breadcrumbs nil)
        (parts (split-sequence #\/ url :remove-empty-subseqs t))
        (current-path ""))
    
    ;; Add root
    (push (cons "/" "Home") breadcrumbs)
    
    ;; Build paths and find matching routes
    (loop for part in parts
          do (progn
               (setf current-path (concatenate 'string current-path "/" part))
               (let ((route (find-matching-route current-path)))
                 (when route
                   (push (cons current-path (or (route-title route) (route-name route)))
                         breadcrumbs)))))
    
    (nreverse breadcrumbs)))

(defun find-matching-route (url)
  "Find a route that matches the given URL."
  (loop for collection being the hash-values of *routes-registry*
        for routes = (collection-routes collection)
        thereis (find-if (lambda (route)
                           (match-url route url))
                         routes)))
