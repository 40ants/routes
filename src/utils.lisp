(uiop:define-package #:40ants-routes/utils
  (:use #:cl)
  (:import-from #:40ants-routes/errors
                #:no-common-elements-error)
  (:export #:make-new-namespace))
(in-package #:40ants-routes/utils)


(defun make-new-namespace (full-namespace relative-namespace)
  "Create a new namespace by combining the full namespace of the current page
   with a partial namespace of the target page.

   Examples:

   ```
   (make-new-namespace '(\"server\" \"app\" \"blog\" \"post\")
                       '(\"app\" \"admin\" \"users\"))
   ;; => (\"server\" \"app\" \"admin\" \"users\")

   (make-new-namespace '(\"server\" \"app\" \"blog\" \"post\")
                       '(\"blog\" \"moderation\" \"posts\"))
   ;; => (\"server\" \"app\" \"blog\" \"moderation\" \"posts\")

   (make-new-namespace '(\"server\" \"app\" \"blog\" \"post\")
                       '(\"app\"))
   ;; => (\"server\" \"app\")

   (make-new-namespace '(\"server\" \"app\" \"blog\" \"post\")
                       '(\"server\" \"another-app\" \"images\"))
   ;; => (\"server\" \"another-app\" \"images\")

   (make-new-namespace '(\"server\" \"app\" \"blog\" \"post\")
                       '(\"some-other-server\" \"app\" \"admin\"))
   ;; => signals error NO-COMMON-ELEMENTS-ERROR
   ```"
  
  (if (null relative-namespace)
      full-namespace
      (let* ((first-rel-part (first relative-namespace))
             (intersection-position
               (position first-rel-part full-namespace :test #'string=)))
        (cond
          ;; If the first element of relative-namespace matches the first element of full-namespace,
          ;; we need to check if it's a complete replacement or just a partial one
          (intersection-position
           (let ((common-prefix (subseq full-namespace
                                        0
                                        (1+ intersection-position)))
                 (rest-part (rest relative-namespace)))
             (append common-prefix
                     rest-part)))
          ;; If there are no common elements between the namespaces, signal an error
          (t
           (error 'no-common-elements-error
                  :full-namespace full-namespace
                  :relative-namespace relative-namespace))))))
