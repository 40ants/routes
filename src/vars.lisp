(uiop:define-package #:40ants-routes/vars
  (:use #:cl))
(in-package #:40ants-routes/vars)


;; Dynamic variables to store current context
(defvar *current-namespace* nil
  "Current namespace for route resolution.")

(defvar *current-routes* nil
  "Current route collection for route resolution.")

