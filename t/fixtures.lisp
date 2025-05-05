(uiop:define-package #:40ants-routes-tests/fixtures
  (:use #:cl)
  (:import-from #:serapeum
                #:eval-always
                #:fmt)
  (:shadowing-import-from #:40ants-routes/defroutes
                          #:defroutes
                          #:get
                          #:post
                          #:put
                          #:include))
(in-package #:40ants-routes-tests/fixtures)


(eval-always
  (defun get-user-name (&key id &allow-other-keys)
    "A function for retrieving user names"
    (cond
      ((= id 123)
       "Petya")
      ((= id 42)
       "Vasya")
      (t
       "Unknown user"))))



;; Define test routes for a blog library
(defroutes (*blog-routes* :namespace "blog")
  (get ("/" :name "index"
            :title "Blog")
    (fmt "Blog index"))
  (get ("/<string:slug>" :name "post"
                         :title "Post")
    (fmt "Blog post: ~A" slug)))


;; Define test routes for an admin library
(defroutes (*admin-users-routes* :namespace "users")
  (post ("/" :name "users" :title "Users")
    (fmt "Users list"))
  (get ("/<int:id>"
        :name "user"
        ;; Example of using a function for retrieving
        ;; route title in runtime:
        :title #'get-user-name)
    (fmt "User profile: ~A" id))
  (put ("/<int:id>" :name "user-update" :title "Update User")
    (fmt "Update user profile: ~A" id)))


(defroutes (*admin-posts-routes* :namespace "posts")
  (post ("/" :name "posts" :title "Posts")
    (fmt "Posts list"))
  (get ("/<string:slug>" :name "post" :title "Post")
    (fmt "Post: ~A" slug)))


(defroutes (*admin-routes* :namespace "admin")
  (get ("/" :name "admin-index" :title "Admin")
    (fmt "Admin index"))
  (include *admin-users-routes*
           :path "/users/")
  (include *admin-posts-routes*
           :path "/posts/"))


;; Define test routes for an application
(defroutes (*app-routes* :namespace "app")
  (get ("/" :name "index" :title "Home")
    (fmt "App index"))
  (include *blog-routes*
           :path "/blog/")
  (include *admin-routes*
           :path "/admin/"))


