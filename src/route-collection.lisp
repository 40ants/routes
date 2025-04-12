(uiop:define-package #:40ants-routes/route-collection
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:match-url)
  (:export #:route-collection
           #:collection-routes
           #:collection-namespace))
(in-package #:40ants-routes/route-collection)


(defclass route-collection ()
  ((routes :initarg :routes
           :accessor collection-routes
           :initform nil
           :documentation "List of routes in this collection")
   ;; (namespace :initarg :namespace
   ;;            :reader collection-namespace
   ;;            :documentation "Namespace of this collection")
   ))


(defun route-collection-p (obj)
  (typep obj 'route-collection))


(defmethod match-url ((obj route-collection) (url string) &key on-match)
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
      
      (loop for subroute in (collection-routes obj)
            thereis (match-url subroute url
                               :on-match (when on-match
                                           #'add-collection-if-needed))))))
