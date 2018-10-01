#!/usr/bin/env groovy

library("govuk")

node {
  govuk.buildProject(
    beforeTest: {
      govuk.setEnvar("GOVUK_UPSTREAM_URI", "http://test.example.com")
    },
  )
}
