context("Test dyno")


test_that("Dyno", {
  dyno <- dyno()
  expect_null(dyno)
})
