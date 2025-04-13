(uiop:define-package #:40ants-routes-tests/utils
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:signals)
  (:import-from #:40ants-routes/errors
                #:no-common-elements-error)
  (:import-from #:40ants-routes/utils
                #:make-new-namespace))

(in-package #:40ants-routes-tests/utils)

(deftest test-make-new-namespace ()
  (testing "When relative namespace starts with a part found in full namespace"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '("app" "admin" "users"))
           (result (make-new-namespace full-namespace relative-namespace)))
      (ok (equal result '("server" "app" "admin" "users"))
          "Should replace from the matching part to the end")))
  
  (testing "When relative namespace starts with a part found deeper in full namespace"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '("blog" "moderation" "posts"))
           (result (make-new-namespace full-namespace relative-namespace)))
      (ok (equal result '("server" "app" "blog" "moderation" "posts"))
          "Should replace from the matching part to the end")))
  
  (testing "When relative namespace is a single element found in full namespace"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '("app"))
           (result (make-new-namespace full-namespace relative-namespace)))
      (ok (equal result '("server" "app"))
          "Should truncate the namespace at the matching part")))
  
  (testing "When relative namespace starts with the same element as full namespace"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '("server" "another-app" "images"))
           (result (make-new-namespace full-namespace relative-namespace)))
      (ok (equal result '("server" "another-app" "images"))
          "Should use the relative namespace as is")))
  (testing "When relative namespace has a common element but not as the first element"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '("unknown" "app" "admin"))
           (result (make-new-namespace full-namespace relative-namespace)))
      (ok (equal result '("server" "app" "admin"))
          "Should replace from the matching part to the end")))
  
  
  (testing "When relative namespace is empty"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '())
           (result (make-new-namespace full-namespace relative-namespace)))
      (ok (equal result full-namespace)
          "Should return the full namespace unchanged")))
  
  (testing "When there are no common elements between namespaces"
    (let* ((full-namespace '("server" "app" "blog" "post"))
           (relative-namespace '("completely" "different" "namespace")))
      (handler-case
          (progn
            (make-new-namespace full-namespace relative-namespace)
            (ok nil "Should have signaled an error"))
        (no-common-elements-error (e)
          (ok t "Correctly signaled no-common-elements-error")
          (ok (string= (format nil "There is no common elements between ~S and ~S namespaces."
                               full-namespace relative-namespace)
                       (format nil "~A" e))
              "Error message is correct")))))
  
  (testing "When first elements are different but there are common elements later"
    (let* ((full-namespace '("foo" "app" "users"))
           (relative-namespace '("bar" "app" "admin")))
      (handler-case
          (progn
            (make-new-namespace full-namespace relative-namespace)
            (ok nil "Should have signaled an error"))
        (no-common-elements-error (e)
          (ok t "Correctly signaled no-common-elements-error")
          (ok (string= (format nil "There is no common elements between ~S and ~S namespaces."
                               full-namespace relative-namespace)
                       (format nil "~A" e))
              "Error message is correct"))))))