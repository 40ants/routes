(defsystem "40ants-routes-tests"
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "BSD"
  :homepage "https://40ants.com/routes"
  :class :package-inferred-system
  :description "Provides tests for 40ants-routes."
  :source-control (:git "https://github.com/40ants/routes")
  :bug-tracker "https://github.com/40ants/routes/issues"
  :pathname "t"
  :depends-on ("40ants-routes-tests/core")
  :perform (test-op (op c)
                    (unless (symbol-call :rove :run c)
                      (error "Tests failed"))))
