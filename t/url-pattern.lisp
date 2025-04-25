(uiop:define-package #:40ants-routes-tests/url-pattern
  (:use #:cl)
  (:import-from #:rove
                #:ok
                #:testing
                #:deftest)
  (:import-from #:40ants-routes/url-pattern
                #:parse-url-pattern)
  (:import-from #:serapeum
                #:fmt)
  (:import-from #:40ants-routes/url-pattern
                #:replace-parameters))
(in-package #:40ants-routes-tests/url-pattern)


(defun check-parsing (url expected-regex-pattern &optional expected-args)
  (let* ((pattern (parse-url-pattern url))
         (regex (40ants-routes/url-pattern::url-pattern-regex pattern))
         (params (40ants-routes/url-pattern::url-pattern-params pattern))
         (results (list regex params))
         (matchedp (equal results
                          (list expected-regex-pattern
                                expected-args))))
    (ok matchedp
        (if matchedp
            (fmt "(parse-url-pattern ~S) should return (~S ~S)"
                 url
                 expected-regex-pattern
                 expected-args)
            (fmt "(parse-url-pattern ~S) should return (~S ~S) but returned ~S"
                 url
                 expected-regex-pattern
                 expected-args
                 results)))))


(deftest test-pattern-parsing ()
  (testing "URL without params"
    (check-parsing "/" "^/$")
    (check-parsing "/blog" "^/blog$")
    (check-parsing "/blog/" "^/blog/$"))
  
  (testing "URL with args"
    (check-parsing "/<int:foo>"
                   "^/(\\d+)$"
                   '((:foo "int")))
    (check-parsing "/blog/<string:slug>"
                   "^/blog/([^/]+)$"
                   '((:slug "string")))))


(defun check-matching (pattern url &optional (expected-match-p t) expected-params)
  (let* ((url-pattern (parse-url-pattern pattern)))
    (multiple-value-bind (matchedp params)
        (40ants-routes/url-pattern::match-url url-pattern
                                              url)
      (let ((test-result
              (equal (list matchedp
                           params)
                     (list expected-match-p
                           expected-params))))
        (ok test-result
            (if test-result
                (if expected-params
                    (fmt "URL ~S ~A pattern ~S and return params ~S"
                         url
                         (if expected-match-p
                             "should match"
                             "should not match")
                         pattern
                         expected-params)
                    (fmt "URL ~S ~A pattern ~S"
                         url
                         (if expected-match-p
                             "should match"
                             "should not match")
                         pattern))
                (if expected-params
                    (fmt "URL ~S ~A pattern ~S and return params ~S, but it ~A and returned params ~S"
                         url
                         (if expected-match-p
                             "should match"
                             "should not match")
                         pattern
                         expected-params
                         (if matchedp
                             "matched"
                             "didn't matched")
                         params)
                    (fmt "URL ~S ~A pattern ~S, but it does not match"
                         url
                         (if expected-match-p
                             "should match"
                             "should not match")
                         pattern))))))))


(deftest test-pattern-matching ()
  (testing "Without params"
    (check-matching "/blog" "/blog")
    (check-matching "/blog"
                    "/blog2" nil)
    ;; Regex in pattern right now workw too,
    ;; but probably we should prohibit it?
    (check-matching "/blog.*"
                    "/blog-foo"))

  (testing "With params"
    (check-matching "/blog/<string:slug>/edit"
                    "/blog/foo-bar/edit"
                    t
                    '((:slug . "foo-bar")))))


(deftest test-regex-pattern-matching ()
  (testing "With regex patterns in params"
    ;; Test with wildcard regex pattern
    (check-matching "/files/<.*:path>"
                    "/files/some/nested/path/file.txt"
                    t
                    '((:path . "some/nested/path/file.txt")))
    
    ;; Test with more specific regex pattern (starts with lowercase letter, followed by lowercase letters or numbers)
    (check-matching "/files/<[a-z][a-z0-9]+:path>"
                    "/files/abc123"
                    t
                    '((:path . "abc123")))
    
    ;; Test with more specific regex pattern that should not match
    (check-matching "/files/<[a-z][a-z0-9]+:path>"
                    "/files/ABC123"
                    nil)
    
    ;; Test with empty path for wildcard pattern
    (check-matching "/files/<.*:path>"
                    "/files/"
                    t
                    '((:path . "")))))


(defun check-parameters-replacing (pattern params expected-result)
  (let* ((url-pattern (parse-url-pattern pattern))
         (result (replace-parameters url-pattern params))
         (matchedp (equal result
                          expected-result)))
    (ok matchedp
        (fmt "Parameter replacing for pattern ~S and params ~S should return ~S"
             pattern
             params
             expected-result))))


(deftest test-replace-parameters ()
  (testing "Without params"
    (check-parameters-replacing "/" nil
                                "/")
    (check-parameters-replacing "/blog" nil
                                "/blog"))
  (testing "With params"
    (check-parameters-replacing "/blog/<string:slug>" '(:slug "foo-bar")
                                "/blog/foo-bar")
    (check-parameters-replacing "/blog/<string:slug>/comments/<int:thread-id>" '(:slug "foo-bar"
                                                                                 :thread-id 100500)
                                "/blog/foo-bar/comments/100500")))
