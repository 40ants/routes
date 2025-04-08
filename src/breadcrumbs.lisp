(uiop:define-package #:40ants-routes/breadcrumbs
  (:use #:cl)
  (:import-from #:split-sequence
                #:split-sequence)
  (:export #:get-breadcrumbs))
(in-package #:40ants-routes/breadcrumbs)

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