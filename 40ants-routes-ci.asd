(defsystem "40ants-routes-ci"
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "BSD"
  :homepage "https://40ants.com/routes"
  :class :package-inferred-system
  :description "Provides CI settings for 40ants-routes."
  :source-control (:git "https://github.com/40ants/routes")
  :bug-tracker "https://github.com/40ants/routes/issues"
  :pathname "src"
  :depends-on ("40ants-ci"
               "40ants-routes-ci/ci"))
