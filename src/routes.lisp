(uiop:define-package #:40ants-routes/routes
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:format-url
                #:match-url
                #:url-path
                #:node-namespace
                #:has-namespace-p)
  (:import-from #:serapeum
                #:dict)
  (:import-from #:40ants-routes/route
                #:routep
                #:route)
  (:import-from #:40ants-routes/errors
                #:namespace-duplication-error
                #:path-duplication-error)
  (:export #:routes
           #:children-routes))
(in-package #:40ants-routes/routes)


(defclass routes ()
  ((children :initarg :children
             :accessor children-routes
             :initform nil
             :documentation "List of children in this collection.")
   (namespace :initarg :namespace
              :type string
              :accessor node-namespace
              :documentation "Namespace of this routes collection.")))


(defmethod print-object ((obj routes) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~S ~A subroute~:P"
            (node-namespace obj)
            (length (children-routes obj)))))


(defun routesp (obj)
  (typep obj 'routes))


(defmethod (setf children-routes) :around (new-routes (obj routes))
  ;; Validating if there are some namespaces duplication
  (loop with seen-namespaces = (dict)
        for item in new-routes
        for namespace = (when (has-namespace-p item)
                          (node-namespace item))
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


(defmethod format-url ((obj routes) stream args &optional route-name)
  (declare (ignore route-name))
  (values))


(defmethod has-namespace-p ((obj routes))
  (values t))
