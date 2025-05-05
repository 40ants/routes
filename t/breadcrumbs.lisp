(uiop:define-package #:40ants-routes-tests/breadcrumbs
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:ok
                #:testing
                #:ng)
  (:import-from #:40ants-routes/with-url
                #:with-url)
  (:import-from #:40ants-routes/breadcrumbs
                #:breadcrumb-title
                #:breadcrumb-path
                #:get-breadcrumbs)
  (:import-from #:40ants-routes-tests/fixtures
                #:*app-routes*))
(in-package #:40ants-routes-tests/breadcrumbs)


(deftest test-breadcrumbs ()
  "Test breadcrumbs generation."
  (testing "Breadcrumbs generation"
    (with-url (*app-routes* "/admin/users/123")
      (let ((crumbs (get-breadcrumbs)))
        (ok (= (length crumbs) 4) "Breadcrumbs have correct length")

        (when (= (length crumbs) 4)
          (let ((paths (mapcar #'breadcrumb-path
                               crumbs))
                (titles (mapcar #'breadcrumb-title
                                crumbs)))
            (ok (equal paths
                       '("/" "/admin/" "/admin/users/" "/admin/users/123")))
            (ok (equal titles
                       '("Home" "Admin" "Users" "Petya"))))))))

  (testing "Breadcrumbs can change depending extracted parameters"
    (with-url (*app-routes* "/admin/users/42")
      (let ((titles (mapcar #'breadcrumb-title
                            (get-breadcrumbs))))
        (ok (equal titles
                   ;; This time, the username is different
                   '("Home" "Admin" "Users" "Vasya")))))))
