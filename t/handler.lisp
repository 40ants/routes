(uiop:define-package #:40ants-routes-tests/handler
  (:use #:cl)
  (:import-from #:rove
                #:testing
                #:ok
                #:deftest)
  (:import-from #:serapeum
                #:fmt)
  (:import-from #:40ants-routes/with-url
                #:with-url)
  (:import-from #:40ants-routes/handler
                #:call-handler)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:get
                          #:include
                          #:defroutes))
(in-package #:40ants-routes-tests/handler)


(defroutes (*blog*)
  (get ("/" :name "index")
    "List of blog posts")
  (get ("/post-<int:post-id>" :name "index")
    (fmt "Blog post ~S"
         post-id)))


(defroutes (*app*)
  (include *blog*
           :path "/blog/"))


(defun check-url (url expected-handler-result)
  (with-url (*app* url)
    (let* ((result (call-handler))
           (matchedp (equal result
                            expected-handler-result)))
      (ok matchedp
          (fmt "Result ~S should be ~S"
               result
               expected-handler-result)))))


(deftest test-handler-will-be-called-with-params ()
  
  (testing "First URL"
    (check-url "/blog/post-100500" "Blog post 100500"))
  
  (testing "Second URL"
    (check-url "/blog/post-42" "Blog post 42"))
  
  (testing "Third URL"
    (check-url "/blog/" "List of blog posts")))
