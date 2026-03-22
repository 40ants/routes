(uiop:define-package #:40ants-routes-tests/extend-routes
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes/defroutes
                #:defroutes
                #:extend-routes)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:get
                          #:post
                          #:put
                          #:delete))
(in-package #:40ants-routes-tests/extend-routes)


(defroutes (*base-routes* :namespace "base")
  (get ("/" :name "index" :title "Base Index")
       (format nil "Base index page"))
  (get ("/old" :name "old" :title "Old Route")
       (format nil "Old route to be replaced")))


(defroutes (*extended-routes* :namespace "extended")
  (get ("/" :name "index" :title "Extended Index")
       (format nil "Extended index page"))
  (get ("/new" :name "new" :title "New Route")
       (format nil "New route")))


(deftest test-extend-routes-adds-new-routes ()
  "Test that extend-routes adds new routes to an existing routes collection."
  (testing "Adding new routes to base collection"
    (extend-routes (*base-routes*)
      (get ("/new" :name "new" :title "New Route")
        (format nil "New route from extension"))))
  
  (ok (find-route "new" :namespace "base")
      "New route should be findable")
  (ok (= (length (children-routes *base-routes*))
         2)
      "Should have 2 routes after extension"))


(deftest test-extend-routes-replaces-existing-route ()
  "Test that extend-routes replaces existing routes with same path."
  (testing "Replacing existing route"
    (extend-routes (*base-routes*)
      (get ("/old" :name "new-old" :title "New Old Route")
        (format nil "New route with same path"))))
  
  (let ((old-route (find-route "old" :namespace "base")))
    (ok old-route "Old route should still be found by old name")
    (ok (string= (route-name old-route)
                 "new-old")
        "Route name should be updated"))
  (ok (= (length (children-routes *base-routes*))
         2)
      "Should still have 2 routes after replacement"))


(deftest test-extend-routes-maintains-namespace ()
  "Test that extend-routes maintains the namespace of the target collection."
  (testing "Namespace is preserved after extension"
    (extend-routes (*base-routes*)
      (get ("/extra" :name "extra" :title "Extra")
        (format nil "Extra route"))))
    (ok (string= (node-namespace *base-routes*)
                 "base")
        "Namespace should be 'base' after extension"))


(deftest test-extend-routes-with-multiple-routes ()
  "Test extending with multiple new routes at once."
  (testing "Adding multiple routes"
    (extend-routes (*base-routes*)
      (get ("/route1" :name "route1" :title "Route 1")
        (format nil "Route 1")))
    (extend-routes (*base-routes*)
      (get ("/route2" :name "route2" :title "Route 2")
        (format nil "Route 2")))
    (extend-routes (*base-routes*)
      (get ("/route3" :name "route3" :title "Route 3")
        (format nil "Route 3"))))
    (ok (= (length (children-routes *base-routes*))
             5)
        "Should have 5 routes after adding 3 routes"))


(deftest test-extend-routes-with-other-http-methods ()
  "Test extending routes with different HTTP methods."
  (testing "Adding routes with POST and PUT methods"
    (extend-routes (*base-routes*)
      (post ("/create" :name "create" :title "Create")
        (format nil "Create action")))
    
    (extend-routes (*base-routes*)
      (put ("/update" :name "update" :title "Update")
        (format nil "Update action")))
    
    (let ((create-route (find-route "create" :namespace "base"))
          (update-route (find-route "update" :namespace "base")))
      (ok create-route "Create route should be found")
      (ok (eq (route-method create-route)
              :post)
          "Create route should have POST method")
      (ok update-route "Update route should be found")
      (ok (eq (route-method update-route)
              :put)
          "Update route should have PUT method"))))
