test_that(".lab_format_mes_catala formata correctament", {
  expect_equal(laboR:::.lab_format_mes_catala("202501"), "gener de 2025")
  expect_equal(laboR:::.lab_format_mes_catala("202403"), "març de 2024")
  expect_equal(laboR:::.lab_format_mes_catala("201112"), "desembre de 2011")
})

test_that(".lab_construir_mes_value construeix el value_str del servidor", {
  expect_equal(
    laboR:::.lab_construir_mes_value("202501"),
    "D266CB2011D4C75E2000058EE23BF035:202501~1048576~gener de 2025"
  )
  # Accepta formats amb separadors
  expect_equal(laboR:::.lab_construir_mes_value("2025-01"),
               laboR:::.lab_construir_mes_value("202501"))
  expect_error(laboR:::.lab_construir_mes_value("2025"), "Format de mes")
})

test_that(".lab_validar_mesos valida i neteja", {
  expect_equal(laboR:::.lab_validar_mesos(c("202501", "2025-02")),
               c("202501", "202502"))
  expect_error(laboR:::.lab_validar_mesos(NULL), "almenys un mes")
  expect_error(laboR:::.lab_validar_mesos("20251"), "invalid")
})

test_that("llistar_mesos comença el gener de 2011 i no inclou el mes actual", {
  mesos <- llistar_mesos()
  expect_equal(mesos$codi_mes[1], "201101")
  expect_equal(mesos$etiqueta[1], "gener de 2011")
  expect_false(format(Sys.Date(), "%Y%m") %in% mesos$codi_mes)
})
