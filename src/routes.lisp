(uiop:define-package #:40ants-routes/routes
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:match-url
                #:url-path)
  (:import-from #:serapeum
                #:dict)
  (:import-from #:40ants-routes/route
                #:routep
                #:route)
  (:import-from #:40ants-routes/errors
                #:namespace-duplication-error
                #:path-duplication-error)
  (:export #:routes
           #:children-routes
           #:routes-namespace
           #:add-route))
(in-package #:40ants-routes/routes)

(defclass routes ()
  ((children :initarg :children
             :accessor children-routes
             :initform nil
             :documentation "List of children in this collection.")
   (namespace :initarg :namespace
              :type string
              :accessor routes-namespace
              :documentation "Namespace of this routes collection.")))


(defmethod print-object ((obj routes) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S ~A subroute~:P"
            (routes-namespace obj)
            (length (children-routes obj)))))


(defun routesp (obj)
  (typep obj 'routes))


(defmethod (setf children-routes) :around (new-routes (obj routes))
  ;; Validating if there are some namespaces duplication
  (loop with seen-namespaces = (dict)
        for item in new-routes
        for namespace = (cond
                          ((routep item)
                           nil)
                          (t
                           (routes-namespace item)))
        for existing-item = (when namespace
                              (gethash namespace seen-namespaces))
        when existing-item
          do (error 'namespace-duplication-error
                    :existing-route existing-item
                    :new-route item
                    :namespace namespace)
        do (setf (gethash namespace seen-namespaces)
                 item))
  (call-next-method))


(defmethod match-url ((obj routes) (url string) &key on-match)
  (let ((already-added nil))
    (flet ((add-collection-if-needed (matched-child)
             ;; We need this function to add mached current object and
             ;; matched child in the correct order:
             (unless already-added
               (funcall on-match obj)
               (setf already-added t))
             (funcall on-match
                      matched-child)))
      (declare (dynamic-extent #'add-collection-if-needed))

      (loop for subroute in (children-routes obj)
            thereis (match-url subroute url
                               :on-match (when on-match
                                           #'add-collection-if-needed))))))


(defmethod 40ants-routes/generics::format-url ((obj routes) stream args)
  (values))


(defgeneric add-route (routes route &key override)
  (:documentation "Add a route or included-routes object to the routes collection at runtime.
If a route with the same path or namespace already exists, an error will be signaled
unless override is set to true."))

;; Method for regular routes
(defmethod add-route ((routes routes) (route route) &key override)
  "Add a route to the routes collection at runtime.
If a route with the same path already exists, an error will be signaled
unless override is set to true."
  (let* ((children (children-routes routes))
         (path (url-path route))
         (duplicate-found nil)
         (duplicate-route nil))
    
    ;; Check for path duplication
    (loop for existing-route in children
          when (and (routep existing-route)
                    (equal (princ-to-string (url-path existing-route))
                           (princ-to-string path)))
          do (setf duplicate-found t
                   duplicate-route existing-route)
             (return))
    
    (cond
      ;; If duplicate found and override is true, remove the old route
      ((and duplicate-found override)
       (setf (slot-value routes 'children) 
             (cons route (remove duplicate-route children))))
      
      ;; If duplicate found and override is false, signal an error
      (duplicate-found
       (error 'path-duplication-error
              :existing-route duplicate-route
              :new-route route
              :path path))
      
      ;; No duplicate found, just add the route
      (t
       (setf (children-routes routes) (cons route children))))
    
    route))

;; Method for any other type
(defmethod add-route ((routes routes) (route t) &key override)
  "Add any other type of object to the routes collection at runtime.
If the object has a namespace and a route with the same namespace already exists,
an error will be signaled unless override is true."
  (let* ((children (children-routes routes))
         (has-namespace (and (not (routep route))
                             (slot-exists-p route 'namespace)))
         (namespace (when has-namespace
                      (routes-namespace route)))
         (duplicate-found nil)
         (duplicate-route nil))
    
    ;; Check for namespace duplication if the route has a namespace
    (when (and has-namespace namespace)
      (loop for existing-route in children
            when (and (not (routep existing-route))
                      (string= (routes-namespace existing-route) namespace))
            do (setf duplicate-found t
                     duplicate-route existing-route)
               (return)))
    
    (cond
      ;; If duplicate found and override is true, remove the old route and add the new one
      ((and duplicate-found override)
       (let ((new-children (remove duplicate-route children)))
         ;; Directly set the slot value to bypass the :around method
         (setf (slot-value routes 'children) (cons route new-children))))
      
      ;; If duplicate found and override is false, signal an error
      (duplicate-found
       (error 'namespace-duplication-error
              :existing-route duplicate-route
              :new-route route
              :namespace namespace))
      
      ;; No duplicate found, just add the route
      (t
       (setf (children-routes routes) (cons route children))))
    
    route))
