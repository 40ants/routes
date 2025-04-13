(uiop:define-package #:40ants-routes-tests/with-url
  (:use #:cl)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:defroutes
                          #:include
                          #:get)
  (:import-from #:40ants-routes/with-url
                #:with-url
                #:find-route-for-url)
  (:import-from #:rove
                #:ng
                #:testing
                #:ok
                #:deftest)
  (:import-from #:serapeum
                #:eval-always
                #:fmt)
  (:import-from #:40ants-routes/vars
                #:*routes-path*
                #:*current-routes*)
  (:import-from #:40ants-routes/included-routes
                #:included-routes
                #:included-routes-p
                #:included-routes-original-collection)
  (:import-from #:40ants-routes/routes
                #:routesp))
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
           :path "/foo/"
           :namespace "foo-ns"))

(defroutes (*app* :namespace "app")
  (get ("/" :name "index")
       (fmt "App index"))
  (include *bar*
           :path "/bar/"
           :namespace "bar-ns"))


(deftest test-route-search ()
  (testing "Search for foo index"
    (let ((result
            (find-route-for-url *app*
                                "/bar/foo/")))
      (ok result)
      (ok (typep result
                 '40ants-routes/route::route))
      (ok (string= (40ants-routes/route:route-name result)
                   "index"))
      (ok (string= (funcall
                    (40ants-routes/route:route-handler result))
                   "Foo index")))))


(deftest test-with-routes ()
  (testing "WITH-URL macro should search a route matching given URL"
    (with-url (*app* "/bar/foo/some-post")
      (ng (eql *app*
               *current-routes*)
          "Current route should not be equal to the root routes object")
      (ok (= (length *routes-path*)
             4))
      (testing "First route in the path"
        (let ((route (elt *routes-path* 0)))
          (ok (eql route *foo-slug-route*)
              "Should be /<string:slug> of foo library.")))
      
      (testing "Second route in the path"
        (let ((route (elt *routes-path* 1)))
          (ok (included-routes-p route))
          (when (included-routes-p route)
            (ok (eql (included-routes-original-collection route)
                     *foo*)
                "Should be all routes of foo library."))))
      
      (testing "Third route in the path"
        (let ((route (elt *routes-path* 2)))
          (ok (included-routes-p route))
          (when (included-routes-p route)
            (ok (eql (included-routes-original-collection route)
                     *bar*)
                "Should be all routes of bar library."))))
      
      (testing "Last route in the path"
        (let ((route (elt *routes-path* 3)))
          (ok (routesp route))
          (ok (eql route
                   *app*)
              "Should be all routes of the application."))))))
