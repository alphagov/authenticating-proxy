#!/usr/bin/env groovy

library("govuk")

node ('mongodb-2.4') {
  govuk.buildProject(
    beforeTest: {
      govuk.setEnvar("GOVUK_UPSTREAM_URI", "http://test.example.com")
      govuk.runRakeTask("db:reset")
    },
  )
}
