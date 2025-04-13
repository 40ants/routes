(uiop:define-package #:40ants-routes/with-parent
  (:use #:cl)
  (:import-from #:40ants-routes/generics
                #:parent))
(in-package #:40ants-routes/with-parent)


(defclass with-parent ()
  ((parent :initform nil
           :accessor parent))
  (:documentation "Helper class to make all types of nodes can be set parent node."))
