# Tests que toquen el servidor de l'Observatori: se salten sense connexió.

test_that("les llistes de territori retornen els recomptes esperats", {
  skip_if_offline("observatorideltreball.gencat.cat")

  provincies <- obtenir_provincies()
  expect_equal(nrow(provincies), 4)
  expect_setequal(provincies$nom,
                  c("Barcelona", "Girona", "Lleida", "Tarragona"))

  comarques <- obtenir_comarques()
  expect_equal(nrow(comarques), 43)
})

test_that("una descàrrega petita de cada mòdul funciona", {
  skip_if_offline("observatorideltreball.gencat.cat")

  atur <- descarrega_atur_catalunya(mes = "202501", verbose = FALSE)
  expect_true(is.numeric(atur[["Atur registrat"]]))
  expect_true(all(c("Mes", "Mes_etiqueta") %in% names(atur)))

  cont <- descarrega_contractacio_catalunya(mes = "202501", verbose = FALSE)
  expect_true(is.numeric(cont$Contractes))
  expect_equal(cont$Mes, 202501)
})
