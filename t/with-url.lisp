(uiop:define-package #:40ants-routes-tests/with-url
  (:use #:cl)
  (:import-from #:40ants-routes
                #:defroutes
                #:include)
  (:import-from #:40ants-routes/with-url
                #:find-route-for-url)
  (:import-from #:rove
                #:testing
                #:ok
                #:deftest))
(in-package #:40ants-routes-tests/with-url)


(defroutes (*foo*)
  (get ("/" :name "index")
       (fmt "Foo index"))
  (get ("/<string:slug>" :name "foo-route")
       (fmt "Foo route: ~A" slug)))

(defroutes (*bar*)
  (get ("/" :name "index")
       (fmt "Bar index"))
  (include *foo*
           :path "/foo/"
           :namespace "foo-ns"))

;; Define test routes for an application
(defroutes (*app*)
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
      (ok (string= (40ants-routes/route::route-name result)
                   "index"))
      (ok (string= (40ants-routes/route::route-handler result)
                   "Foo index")))))

