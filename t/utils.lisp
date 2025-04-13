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

;;;; Test Utilities

(defparameter *standard-full-namespace* '("server" "app" "blog" "post")
  "Standard full namespace used in most tests.")

(defun assert-namespace-result (full-namespace relative-namespace expected-result &optional (description ""))
  "Helper function to assert that make-new-namespace returns the expected result."
  (let ((result (make-new-namespace full-namespace relative-namespace)))
    (ok (equal result expected-result)
        (format nil "~A~@[ - ~A~]"
                (if (equal result expected-result)
                    "Result matches expected output"
                    (format nil "Expected ~S but got ~S" expected-result result))
                description))))

(defun assert-error-signaled (full-namespace relative-namespace &optional (description ""))
  "Helper function to assert that make-new-namespace signals a no-common-elements-error."
  (handler-case
      (progn
        (make-new-namespace full-namespace relative-namespace)
        (ok nil (format nil "Should have signaled an error~@[ - ~A~]" description)))
    (no-common-elements-error (e)
      (ok t (format nil "Correctly signaled no-common-elements-error~@[ - ~A~]" description))
      (ok (string= (format nil "There is no common elements between ~S and ~S namespaces."
                           full-namespace relative-namespace)
                   (format nil "~A" e))
          "Error message is correct"))))

;;;; Basic Functionality Tests

(deftest test-make-new-namespace-basic ()
  "Test basic functionality of make-new-namespace."
  (testing "When relative namespace is empty"
    (assert-namespace-result *standard-full-namespace* '()
                            *standard-full-namespace*
                            "Should return the full namespace unchanged")))

;;;; Matching First Element Tests

(deftest test-make-new-namespace-matching-first-element ()
  "Test cases where the first element of relative namespace matches an element in full namespace."
  
  (testing "When relative namespace starts with the same element as full namespace"
    (assert-namespace-result *standard-full-namespace*
                            '("server" "another-app" "images")
                            '("server" "another-app" "images")
                            "Should use the relative namespace as is"))
  
  (testing "When relative namespace is a single element matching the first element"
    (assert-namespace-result *standard-full-namespace*
                            '("server")
                            '("server")
                            "Should return just the first element")))

;;;; Matching Element Tests

(deftest test-make-new-namespace-matching-elements ()
  "Test cases where an element of relative namespace matches an element in full namespace."
  
  (testing "When relative namespace starts with a part found in full namespace"
    (assert-namespace-result *standard-full-namespace*
                            '("app" "admin" "users")
                            '("server" "app" "admin" "users")
                            "Should replace from the matching part to the end"))
  
  (testing "When relative namespace starts with a part found deeper in full namespace"
    (assert-namespace-result *standard-full-namespace*
                            '("blog" "moderation" "posts")
                            '("server" "app" "blog" "moderation" "posts")
                            "Should replace from the matching part to the end"))
  
  (testing "When relative namespace is a single element found in full namespace"
    (assert-namespace-result *standard-full-namespace*
                            '("app")
                            '("server" "app")
                            "Should truncate the namespace at the matching part"))
  
  (testing "When relative namespace has a common element but not as the first element"
    (assert-namespace-result *standard-full-namespace*
                            '("unknown" "app" "admin")
                            '("server" "app" "admin")
                            "Should replace from the matching part to the end")))

;;;; Error Cases Tests

(deftest test-make-new-namespace-error-cases ()
  "Test cases where make-new-namespace should signal an error."
  
  (testing "When there are no common elements between namespaces"
    (assert-error-signaled *standard-full-namespace*
                          '("completely" "different" "namespace")
                          "Should signal an error when namespaces have no common elements"))
  
  (testing "When first elements are different but there are common elements later"
    (assert-error-signaled '("foo" "app" "users")
                          '("bar" "app" "admin")
                          "Should signal an error in this special case")))

;;;; Edge Cases Tests

(deftest test-make-new-namespace-edge-cases ()
  "Test edge cases for make-new-namespace."
  
  (testing "When full namespace is empty"
    (assert-error-signaled '() '("some" "namespace")
                          "Should signal an error when full namespace is empty"))
  
  (testing "When both namespaces are empty"
    (assert-namespace-result '() '()
                            '()
                            "Should return an empty list"))
  
  (testing "When namespaces have multiple common elements"
    (assert-namespace-result '("a" "b" "c" "d" "e")
                            '("x" "y" "c" "z")
                            '("a" "b" "c" "z")
                            "Should replace from the first common element")))
