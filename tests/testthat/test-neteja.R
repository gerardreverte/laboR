test_that(".lab_llegir_csv converteix '#' en NA i interpreta els milers", {
  linies <- c(
    "Mes,,Municipi,,Metrics,Contractes",
    "202501,gener de 2025,08121,Mataró,,\"6,131\"",
    "202501,gener de 2025,25120,Ivars d'Urgell,,#"
  )
  raw_utf8 <- charToRaw(paste0(paste(linies, collapse = "\n"), "\n"))
  df <- laboR:::.lab_llegir_csv(raw_utf8)

  expect_equal(nrow(df), 2)
  expect_true(is.numeric(df$Contractes))
  expect_equal(df$Contractes[1], 6131)   # separador de milers
  expect_true(is.na(df$Contractes[2]))   # secret estadístic
})

test_that(".lab_llegir_csv detecta UTF-16LE pel BOM", {
  # Construïm UTF-16LE manualment: BOM + cada caràcter ASCII seguit de 0x00
  contingut <- "Mes,Valor\n202501,42\n"
  chars <- utf8ToInt(contingut)
  raw_utf16 <- c(as.raw(c(0xFF, 0xFE)),
                 as.raw(as.vector(rbind(chars, 0L))))
  df <- laboR:::.lab_llegir_csv(raw_utf16)
  expect_equal(df$Valor, 42)
})

test_that(".lab_cont_netejar_columnes reanomena i homogeneïtza", {
  df <- data.frame(
    Mes = 202501, X2 = "gener de 2025", Municipi = "08121", X4 = "Mataró",
    `Gran grup ocupació` = "01", X6 = "Directors i gerents",
    Metrics = NA, `Contractes ETT` = 444,
    check.names = FALSE
  )
  names(df)[c(2, 4, 6)] <- c("...2", "...4", "...6")

  net <- laboR:::.lab_cont_netejar_columnes(df)

  expect_equal(names(net),
               c("Mes", "Mes_etiqueta", "Municipi", "Municipi_nom",
                 "Gran grup ocupació_codi", "Gran grup ocupació", "Contractes"))
  expect_false("Metrics" %in% names(net))
  expect_true(is.character(net[["Gran grup ocupació_codi"]]))
  expect_true(is.character(net$Municipi))
})

test_that(".lab_atur_netejar aplica el mapa de noms i força codis a character", {
  df <- data.frame(
    Codi = 202501, Mes = "gener de 2025",
    `Codi Muni.` = 25120, Municipis = "Lleida",
    `Atur registrat` = 6792, buida = NA,
    check.names = FALSE
  )
  net <- laboR:::.lab_atur_netejar(df)

  expect_equal(names(net),
               c("Mes", "Mes_etiqueta", "Municipi", "Municipi_nom",
                 "Atur registrat"))
  expect_true(is.character(net$Municipi))   # 25120 -> "25120"
  expect_false("buida" %in% names(net))     # columna tota NA eliminada
})

test_that("la validació de variables detecta errors d'entrada", {
  expect_error(laboR:::.lab_atur_validar_variables("inventada"),
               "no reconeguda")
  expect_error(
    laboR:::.lab_cont_validar_params("total", "202501", NULL, "nivell_formatiu"),
    "nomes pot anar a variable_files"
  )
  expect_error(
    laboR:::.lab_cont_validar_params("ett", "202501", "sector_economic", NULL),
    "no esta disponible"
  )
  expect_error(
    laboR:::.lab_cont_validar_params("inexistent", "202501", NULL, NULL),
    "no valida"
  )
})
