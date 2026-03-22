(uiop:define-package #:40ants-routes-tests/extend-routes
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes/defroutes
                #:routes
                #:defroutes
                #:extend-routes)
  (:import-from #:40ants-routes/routes
                #:children-routes)
  (:import-from #:40ants-routes/with-url
                #:find-route-for-url)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:get
                          #:post
                          #:put
                          #:delete))
(in-package #:40ants-routes-tests/extend-routes)


(defun create-routes ()
  (routes ("base")
    (get ("/" :name "index" :title "Base Index")
      (format nil "Base index page"))
    (get ("/old" :name "old" :title "Old Route")
      (format nil "Old route to be replaced"))))


(defun call-route (routes url)
  (40ants-routes/with-url:with-url (routes url)
    (40ants-routes/handler:call-handler)))


(deftest test-extend-routes-adds-new-routes ()
  "Test that extend-routes adds new routes to an existing routes collection."
  (let ((routes (create-routes)))
    (testing "Adding new routes to base collection"
      (extend-routes (routes)
        (get ("/new" :name "new" :title "New Route")
          (format nil "New route from extension")))
      
      (ok (string= (call-route routes "/new")
                   "New route from extension")
          "New route should be findable")
      (ok (= (length (children-routes routes))
             3)
          "Should have 3 routes after extension"))))


(deftest test-extend-routes-replaces-existing-route ()
  "Test that extend-routes replaces existing routes with same path."
  (let ((routes (create-routes)))
    (testing "Replacing existing route"
      (extend-routes (routes)
        (get ("/old" :name "new-old" :title "New Old Route")
          (format nil "New route with same path"))))
  
    (let ((route (find-route-for-url routes "/old")))
      (ok route "Old route should still be found by old name")
      (when route
        (ok (string= (40ants-routes/route:route-name route)
                     "new-old")
            "Route name should be updated")))
    
    (ok (= (length (children-routes routes))
           2)
        "Should still have 2 routes after replacement")))
