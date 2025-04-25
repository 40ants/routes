(uiop:define-package #:40ants-routes-tests/with-url
  (:use #:cl)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:defroutes
                          #:include
                          #:get)
  (:import-from #:40ants-routes/with-url
                #:with-url
                #:find-route-for-url)
  (:import-from #:40ants-routes/errors
                #:no-route-for-url-error)
  (:import-from #:rove
                #:ng
                #:testing
                #:ok
                #:deftest)
  (:import-from #:serapeum
                #:eval-always
                #:fmt)
  (:import-from #:40ants-routes/vars
                #:*current-namespace*
                #:*routes-path*
                #:*current-route*)
  (:import-from #:40ants-routes/included-routes
                #:included-routes
                #:included-routes-p
                #:original-routes)
  (:import-from #:40ants-routes/routes
                #:routesp)
  (:import-from #:40ants-routes/matched-route
                #:original-route
                #:matched-route-p)
  (:import-from #:40ants-routes-tests/fixtures
                #:*app-routes*))
(in-package #:40ants-routes-tests/with-url)


(eval-always
  (defvar *foo-slug-route*
    (get ("/<string:slug>" :name "foo-route")
      (fmt "Foo route: ~A" slug))))


(defroutes (*foo* :namespace "foo")
  (get ("/" :name "index")
    (fmt "Foo index"))
  *foo-slug-route*)


(defroutes (*bar* :namespace "bar")
  (get ("/" :name "index")
    (fmt "Bar index"))
  (include *foo*
           :path "/foo/"))

(defroutes (*app* :namespace "app")
  (get ("/" :name "index")
       (fmt "App index"))
  (include *bar*
           :path "/bar/"))


(deftest test-route-search ()
  (testing "Search for foo index"
    (let ((result
            (find-route-for-url *app*
                                "/bar/foo/")))
      (ok result)
      (ok (40ants-routes/matched-route::matched-route-p result))
      (when (40ants-routes/matched-route::matched-route-p result)
        (ok (string= (40ants-routes/route:route-name result)
                     "index"))
        (ok (string= (funcall
                      (40ants-routes/route:route-handler result))
                     "Foo index"))))))


(deftest test-with-routes ()
  (testing "WITH-URL macro should search a route matching given URL"
    (with-url (*app* "/bar/foo/some-post")
      (ng (eql *app*
               *current-route*)
          "Current route should not be equal to the root routes object")
      (ok (= (length *routes-path*)
             4))

      (testing "First route in the path"
        (let ((route (elt *routes-path* 0)))
          (ok (matched-route-p route))
          (when (matched-route-p route)
            (ok (eql (original-route route)
                     *foo-slug-route*)
                "Should be /<string:slug> of foo library."))))
      
      (testing "Second route in the path"
        (let ((route (elt *routes-path* 1)))
          (ok (included-routes-p route))
          (when (included-routes-p route)
            (ok (eql (original-routes route)
                     *foo*)
                "Should be all routes of foo library."))))
      
      (testing "Third route in the path"
        (let ((route (elt *routes-path* 2)))
          (ok (included-routes-p route))
          (when (included-routes-p route)
            (ok (eql (original-routes route)
                     *bar*)
                "Should be all routes of bar library."))))
      
      (testing "Last route in the path"
        (let ((route (elt *routes-path* 3)))
          (ok (routesp route))
          (ok (eql route
                   *app*)
              "Should be all routes of the application."))))))


(deftest test-current-namespace-is-known-during-with-routes ()
  (testing "WITH-URL macro sets current-namespace var"
    (with-url (*app* "/bar/foo/some-post")
      (ok (equal *current-namespace*
                 '("app" "bar" "foo"))))))
(deftest test-no-route-for-url-error ()
  (testing "WITH-URL macro should throw no-route-for-url-error when URL is not found"
    (ok (handler-case
            (with-url (*app* "/non-existent-url")
              nil)
          (no-route-for-url-error (e)
            (string= (40ants-routes/errors:url e)
                     "/non-existent-url"))))))


(deftest test-matched-route-p ()
  "Test that current-route is set to a matched-route when using with-url."
  (testing "Checking if current-route will be set to the route of \"user\" inside admin interface"
    (with-url (*app-routes* "/admin/users/100500")
      (ok (40ants-routes/matched-route::matched-route-p *current-route*)))))
