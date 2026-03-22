(defsystem "40ants-routes-docs"
  :author "Alexander Artemenko <svetlyak.40wt@gmail.com>"
  :license "Unlicense"
  :homepage "https://40ants.com/routes/"
  :class :package-inferred-system
  :description "Documentation for 40ants-routes."
  :source-control (:git "https://github.com/40ants/routes")
  :bug-tracker "https://github.com/40ants/routes/issues"
  :pathname "docs"
  :depends-on ("40ants-routes"
               "40ants-routes-docs/index"
               "40ants-routes-docs/changelog"
               "40ants-doc"))
