(uiop:define-package #:40ants-routes/routes
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:match-url)
  (:import-from #:40ants-routes/with-parent
                #:with-parent)
  (:export #:routes
           #:children-routes))
(in-package #:40ants-routes/routes)


(defclass routes (with-parent)
  ((children :initarg :children
             :accessor children-routes
             :initform nil
             :documentation "List of children in this collection")))


(defun routesp (obj)
  (typep obj 'routes))


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

