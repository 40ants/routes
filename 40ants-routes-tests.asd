(defsystem "40ants-routes-tests"
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "BSD"
  :homepage "https://40ants.com/routes"
  :class :package-inferred-system
  :description "Provides tests for 40ants-routes."
  :source-control (:git "https://github.com/40ants/routes")
  :bug-tracker "https://github.com/40ants/routes/issues"
  :pathname "t"
  :depends-on ("40ants-routes-tests/core"
               "40ants-routes-tests/http-methods"
               "40ants-routes-tests/included-routes"
               "40ants-routes-tests/url-pattern"
               "40ants-routes-tests/with-url"
               "40ants-routes"
               "rove"
               "cl-ppcre"
               "split-sequence")
  :perform (test-op (op c)
                   (unless (symbol-call :rove :run c)
                     (error "Tests failed"))))
