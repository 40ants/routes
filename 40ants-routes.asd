#-asdf3.1 (error "40ants-routes requires ASDF 3.1 because for lower versions pathname does not work for package-inferred systems.")
(defsystem "40ants-routes"
  :description "Framework agnostic URL routing library."
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "Unlicense"
  :homepage "https://40ants.com/routes"
  :source-control (:git "https://github.com/40ants/routes")
  :bug-tracker "https://github.com/40ants/routes/issues"
  :class :40ants-asdf-system
  :defsystem-depends-on ("40ants-asdf-system")
  :pathname "src"
  :depends-on (;; "40ants-routes/core"
               "40ants-routes/route"
               "40ants-routes/routes"
               "40ants-routes/included-routes"
               "40ants-routes/url-pattern"
               "40ants-routes/with-routes"
               "40ants-routes/find-route"
               "40ants-routes/defroutes"
               "40ants-routes/route-url"
               "40ants-routes/breadcrumbs"
               "cl-ppcre"
               "split-sequence")
  :in-order-to ((test-op (test-op "40ants-routes-tests"))))
