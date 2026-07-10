# contractacio.R — descàrrega de dades de contractació laboral.
#
# TIPOLOGIES: "total" (tots els contractes), "ett" (Empreses de Treball
# Temporal), "estrangeres" (persones estrangeres), "estrangeres_regio"
# (persones estrangeres per gran regió de nacionalitat).
#
# LÍMITS TÈCNICS DE L'API:
#   - Màxim 12 mesos per crida (batching automàtic)
#   - Màxim 20 municipis per crida (batching automàtic)
#   - Una variable de desagregació en FILES i una en COLS simultàniament

.LAB_CONT_VIZ <- "W2359"

.LAB_CONT_DOSSIERS <- list(
  total = list(
    cat  = list(id = "2787AC144F0BB6C57A2859ABC9D4B12C",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10"),
    com  = list(id = "5A78263644C92CD970D926818A2D526E",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10"),
    prov = list(id = "799AF87F4D69EA7BB1376984E0930EFF",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10"),
    muni = list(id = "9433C3AB4543E176D0704190F3C3E7ED",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10")
  ),
  ett = list(
    cat  = list(id = "4FDAD2F84BD026C0548C25B9E7C78A36",
                files = "784B53154A5030AC847D06A4BA000C83@0@10",
                cols  = "4B714158475A269F5AE146A930D50A2D@0@10"),
    com  = list(id = "B1AFEFE5417E17DDC05B3C8503B5197D",
                files = "784B53154A5030AC847D06A4BA000C83@0@10",
                cols  = "4B714158475A269F5AE146A930D50A2D@0@10"),
    prov = list(id = "10C01E59428060CBB18E408EEC7FD52D",
                files = "784B53154A5030AC847D06A4BA000C83@0@10",
                cols  = "4B714158475A269F5AE146A930D50A2D@0@10"),
    muni = list(id = "D917FDB44DFC7F90C7AB049052DC0EEA",
                files = "784B53154A5030AC847D06A4BA000C83@0@10",
                cols  = "4B714158475A269F5AE146A930D50A2D@0@10")
  ),
  estrangeres = list(
    cat  = list(id = "60D7A95243C8FE5EDB02A5B55D538128",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10"),
    com  = list(id = "ADA878A845F4005861F5D0A8173905D8",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10"),
    prov = list(id = "CE09C38F46025FD136B41694EBCF33AD",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10"),
    muni = list(id = "5247DFF3496A701AD179669C35057A91",
                files = "FEB6E87C42885551C315BB8709EE5FC3@0@10",
                cols  = "1FCED40D4D6B93C85961CEB7C940D59A@0@10")
  ),
  estrangeres_regio = list(
    cat  = list(id = "2578459643B09D0D01C2BFAD3C93496D",
                files = "26E93DAD402FCDBDBEC31F92DCE19DEB@0@10",
                cols  = "8D1C66B74A3D7D81021C8C9E9627171A@0@10"),
    com  = list(id = "6C5AC4EC4E2BA287895AEF923D071CCF",
                files = "26E93DAD402FCDBDBEC31F92DCE19DEB@0@10",
                cols  = "8D1C66B74A3D7D81021C8C9E9627171A@0@10"),
    prov = list(id = "4792FE3D420E1DA406E5FEB2F0333D01",
                files = "26E93DAD402FCDBDBEC31F92DCE19DEB@0@10",
                cols  = "8D1C66B74A3D7D81021C8C9E9627171A@0@10"),
    muni = list(id = "84D6DD354D4950669817E4AA05B8FF61",
                files = "26E93DAD402FCDBDBEC31F92DCE19DEB@0@10",
                cols  = "8D1C66B74A3D7D81021C8C9E9627171A@0@10")
  )
)

.LAB_CONT_PROMPT_MES       <- "CDA94A6A429498224F6CD587ABBE510F@0@10"
.LAB_CONT_PROMPT_COMARCA   <- "D28CAC094BC809E64839EDB3989897BC@0@10"
.LAB_CONT_PROMPT_PROVINCIA <- "CD1345EC475B554A466AABB0C0D05185@0@10"
.LAB_CONT_PROMPT_MUNICIPI  <- "4AB14277448D036A7ABDF5A8AF10C20E@0@10"

# Variables de desagregació. Les "complexes" (parent_prompt_val no NULL)
# activen un sub-prompt al servidor que es respon en una segona crida.
.LAB_CONT_VARIABLES <- list(
  sexe = list(
    val_str           = "D266E24A11D4C75E2000058EE23BF035~12~Sexe",
    parent_prompt_val = NULL,
    tipologies        = c("total", "ett", "estrangeres", "estrangeres_regio"),
    posicio           = "ambdos",
    descripcio        = "Sexe (Home / Dona)"
  ),
  jornada = list(
    val_str           = "C9B811274366D22A3E223D94A0BF3F74~12~Jornada",
    parent_prompt_val = NULL,
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Jornada (temps complet / parcial / fixos-discontinus)"
  ),
  durada_mesos = list(
    val_str           = "67AD6B0E456E302BE161AFB3F0820AB2~12~Tram durada mesos",
    parent_prompt_val = NULL,
    tipologies        = c("total", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Tram durada en mesos (Total/Estrangeres, 9 trams)"
  ),
  durada_dies = list(
    val_str           = "82638F7345B92A08267B41BCECB39530~12~Tram durada dies",
    parent_prompt_val = NULL,
    tipologies        = c("ett"),
    posicio           = "ambdos",
    descripcio        = "Tram durada en dies (exclusiu ETT)"
  ),
  modalitat_ett = list(
    val_str           = "4BD8BC6340C2F33286959589B030B766~47~Modalitat de contracte",
    parent_prompt_val = NULL,
    tipologies        = c("ett"),
    posicio           = "ambdos",
    descripcio        = "Modalitat de contracte (exclusiu ETT)"
  ),
  nivell_formatiu = list(
    val_str           = "DB228F2140B0C524683753A8D0435D61~12~Grup nivell formatiu",
    parent_prompt_val = NULL,
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "files",
    descripcio        = "Grup nivell formatiu (10 grups) - nomes FILES"
  ),
  grandaria_compte = list(
    val_str           = "B31781B911D4C77D2000058EE23BF035~12~Tram grandaria compte de cotitzacio",
    parent_prompt_val = NULL,
    tipologies        = c("total"),
    posicio           = "files",
    descripcio        = "Tram grandaria compte de cotitzacio (Total, 11 trams) - nomes FILES"
  ),
  indefinit_temporal = list(
    val_str           = "F1BBFBEE11D4C7832000058EE23BF035~12~Indicador indefinit/temporal",
    parent_prompt_val = NULL,
    tipologies        = c("estrangeres_regio"),
    posicio           = "ambdos",
    descripcio        = "Indicador indefinit/temporal (exclusiu estrangeres_regio)"
  ),
  gran_grup_ocupacio_pgr = list(
    val_str           = "D266D61211D4C75E2000058EE23BF035~12~Gran grup ocupacio",
    parent_prompt_val = NULL,
    tipologies        = c("estrangeres_regio"),
    posicio           = "files",
    descripcio        = "Gran grup ocupacio (estrangeres_regio, directa) - nomes FILES"
  ),
  edat_2 = list(
    val_str           = "D266E24F11D4C75E2000058EE23BF035~12~Tram edats (2)",
    parent_prompt_val = "B3547DBA4EB0EFC8AA93108BB2D7F69F~10~Edat",
    sub_prompt_id     = "B3547DBA4EB0EFC8AA93108BB2D7F69F",
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Edat: 2 trams (Menors de 25 anys / De 25 i mes)"
  ),
  edat_3 = list(
    val_str           = "D266E25011D4C75E2000058EE23BF035~12~Tram edats (3)",
    parent_prompt_val = "B3547DBA4EB0EFC8AA93108BB2D7F69F~10~Edat",
    sub_prompt_id     = "B3547DBA4EB0EFC8AA93108BB2D7F69F",
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Edat: 3 trams (Menors 25 / De 25 a 44 / De 45 i mes)"
  ),
  edat_5 = list(
    val_str           = "D266E25111D4C75E2000058EE23BF035~12~Tram edats (5)",
    parent_prompt_val = "B3547DBA4EB0EFC8AA93108BB2D7F69F~10~Edat",
    sub_prompt_id     = "B3547DBA4EB0EFC8AA93108BB2D7F69F",
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Edat: 5 trams"
  ),
  edat_11 = list(
    val_str           = "D266E24E11D4C75E2000058EE23BF035~12~Tram edats (11)",
    parent_prompt_val = "B3547DBA4EB0EFC8AA93108BB2D7F69F~10~Edat",
    sub_prompt_id     = "B3547DBA4EB0EFC8AA93108BB2D7F69F",
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Edat: 11 trams detallats"
  ),
  edat_2_pgr = list(
    val_str           = "D266E24F11D4C75E2000058EE23BF035~12~Tram edats (2)",
    parent_prompt_val = "2B7BF699452178B619FDC0A22BC07AF7~10~Edat.",
    sub_prompt_id     = "2B7BF699452178B619FDC0A22BC07AF7",
    tipologies        = c("estrangeres_regio"),
    posicio           = "ambdos",
    descripcio        = "Edat: 2 trams (exclusiu estrangeres_regio)"
  ),
  edat_3_pgr = list(
    val_str           = "D266E25011D4C75E2000058EE23BF035~12~Tram edats (3)",
    parent_prompt_val = "2B7BF699452178B619FDC0A22BC07AF7~10~Edat.",
    sub_prompt_id     = "2B7BF699452178B619FDC0A22BC07AF7",
    tipologies        = c("estrangeres_regio"),
    posicio           = "ambdos",
    descripcio        = "Edat: 3 trams (exclusiu estrangeres_regio)"
  ),
  indefinit_temporal_tot = list(
    val_str           = "F1BBFBEE11D4C7832000058EE23BF035~12~Indicador indefinit/temporal",
    parent_prompt_val = "78AAFBFA4C655255C39407952ABBDCF5~10~Tipologia de contracte",
    sub_prompt_id     = "78AAFBFA4C655255C39407952ABBDCF5",
    tipologies        = c("total", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Tipologia: Indefinit vs temporal (total/estrangeres)"
  ),
  modalitat = list(
    val_str           = "2CF53507400CF22E494F96B49E9E5B20~12~Modalitat de contracte",
    parent_prompt_val = "78AAFBFA4C655255C39407952ABBDCF5~10~Tipologia de contracte",
    sub_prompt_id     = "78AAFBFA4C655255C39407952ABBDCF5",
    tipologies        = c("total", "estrangeres"),
    posicio           = "ambdos",
    descripcio        = "Tipologia: Modalitat de contracte (total/estrangeres)"
  ),
  gran_grup_ocupacio = list(
    val_str           = "D266D61211D4C75E2000058EE23BF035~12~Gran grup ocupacio",
    parent_prompt_val = "1A5BAE204D0B4559DC9311A4A55A15FC~10~Ocupacio - CCO 2011",
    sub_prompt_id     = "1A5BAE204D0B4559DC9311A4A55A15FC",
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "files",
    descripcio        = "Gran grup ocupacio CCO 2011 (10 grups) - nomes FILES"
  ),
  subgrup_ocupacio = list(
    val_str           = "D266D61711D4C75E2000058EE23BF035~12~Subgrup principal ocupacio",
    parent_prompt_val = "1A5BAE204D0B4559DC9311A4A55A15FC~10~Ocupacio - CCO 2011",
    sub_prompt_id     = "1A5BAE204D0B4559DC9311A4A55A15FC",
    tipologies        = c("total", "ett", "estrangeres"),
    posicio           = "files",
    descripcio        = "Subgrup principal ocupacio CCO 2011 - nomes FILES"
  ),
  sector_economic = list(
    val_str           = "D266D35211D4C75E2000058EE23BF035~12~Sector economic (CCAE 2009)",
    parent_prompt_val = "B509C1C14FC67DDFC8BD519509E22492~10~Activitat economica - CCAE 2009",
    sub_prompt_id     = "B509C1C14FC67DDFC8BD519509E22492",
    tipologies        = c("total", "estrangeres"),
    posicio           = "files",
    descripcio        = "Sector economic CCAE 2009 (4 sectors) - nomes FILES"
  ),
  seccio_economica = list(
    val_str           = "D266D35111D4C75E2000058EE23BF035~12~Seccio economica (CCAE 2009)",
    parent_prompt_val = "B509C1C14FC67DDFC8BD519509E22492~10~Activitat economica - CCAE 2009",
    sub_prompt_id     = "B509C1C14FC67DDFC8BD519509E22492",
    tipologies        = c("total", "estrangeres"),
    posicio           = "files",
    descripcio        = "Seccio economica CCAE 2009 - nomes FILES"
  ),
  divisio_economica = list(
    val_str           = "D266D34F11D4C75E2000058EE23BF035~12~Divisio economica (CCAE 2009)",
    parent_prompt_val = "B509C1C14FC67DDFC8BD519509E22492~10~Activitat economica - CCAE 2009",
    sub_prompt_id     = "B509C1C14FC67DDFC8BD519509E22492",
    tipologies        = c("total", "estrangeres"),
    posicio           = "files",
    descripcio        = "Divisio economica CCAE 2009 (max. desagregacio) - nomes FILES"
  )
)

#' Llista les variables de desagregació disponibles per a la contractació
#'
#' Cada tipologia de contractació admet un subconjunt de variables, que es
#' poden situar a `variable_files` (files) i, si `posicio` és `"ambdos"`,
#' també a `variable_cols` (columnes).
#'
#' @param tipologia Una de `"total"`, `"ett"`, `"estrangeres"` o
#'   `"estrangeres_regio"`. Per defecte `"total"`.
#' @return Un `data.frame` amb les columnes `clau`, `descripcio` i `posicio`
#'   (`"ambdos"` = FILES o COLS; `"files"` = només FILES).
#' @examples
#' llistar_variables_contractacio("total")
#' llistar_variables_contractacio("ett")
#' @export
llistar_variables_contractacio <- function(tipologia = "total") {
  tipologies_valides <- c("total", "ett", "estrangeres", "estrangeres_regio")
  if (!tipologia %in% tipologies_valides) {
    stop("Tipologia '", tipologia, "' no reconeguda. Opcions: ",
         paste(tipologies_valides, collapse = ", "))
  }
  vars <- Filter(function(v) tipologia %in% v$tipologies, .LAB_CONT_VARIABLES)
  data.frame(
    clau       = names(vars),
    descripcio = vapply(vars, function(v) v$descripcio, character(1)),
    posicio    = vapply(vars, function(v) v$posicio, character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}


# nucli — enviar prompts i descarregar CSV -------------------------------------

.lab_cont_enviar_i_descarregar <- function(
    sessio, dossier_id, prompt_files, prompt_cols,
    mes_values, territori_values, prompt_territori,
    variable_files, variable_cols, verbose = FALSE
) {
  var_info_files <- if (!is.null(variable_files)) .LAB_CONT_VARIABLES[[variable_files]] else NULL
  var_info_cols  <- if (!is.null(variable_cols))  .LAB_CONT_VARIABLES[[variable_cols]]  else NULL

  url_prompts <- paste0(.LAB_BASE_URL, "/api/documents/", dossier_id,
                        "/instances/", sessio$instance_id, "/promptsAnswers")

  # unname() és imprescindible: sapply() nomena el vector i as.list() sobre un
  # vector nomenat genera un objecte JSON {"clau":"val"} en lloc de l'array
  # ["val"] que espera el servidor.
  answers <- list(
    list(key = .LAB_CONT_PROMPT_MES, values = unname(as.list(mes_values)),
         useDefault = FALSE)
  )

  if (!is.null(prompt_territori) && length(territori_values) > 0) {
    answers <- c(answers, list(list(
      key = prompt_territori, values = unname(as.list(territori_values)),
      useDefault = FALSE
    )))
  }

  # FILES: per a variables complexes (~10~) s'envia primer el parent
  if (!is.null(var_info_files) && !is.null(var_info_files$parent_prompt_val)) {
    answers <- c(answers, list(list(
      key = prompt_files, values = list(var_info_files$parent_prompt_val),
      useDefault = FALSE)))
  } else if (!is.null(var_info_files)) {
    answers <- c(answers, list(list(
      key = prompt_files, values = list(var_info_files$val_str),
      useDefault = FALSE)))
  } else {
    answers <- c(answers, list(list(key = prompt_files, values = list(),
                                    useDefault = TRUE)))
  }

  # COLS: idem
  if (!is.null(var_info_cols) && !is.null(var_info_cols$parent_prompt_val)) {
    answers <- c(answers, list(list(
      key = prompt_cols, values = list(var_info_cols$parent_prompt_val),
      useDefault = FALSE)))
  } else if (!is.null(var_info_cols)) {
    answers <- c(answers, list(list(
      key = prompt_cols, values = list(var_info_cols$val_str),
      useDefault = FALSE)))
  } else {
    answers <- c(answers, list(list(key = prompt_cols, values = list(),
                                    useDefault = TRUE)))
  }

  if (verbose) message("    Enviant prompts al servidor...")
  resp1 <- .lab_req(url_prompts, "POST",
                    list(messageName = "", answers = answers,
                         personalAnswers = list()),
                    sessio$auth_token, sessio$cookies)
  if (!httr2::resp_status(resp1) %in% c(200, 204)) {
    stop("Error enviant prompts (HTTP ", httr2::resp_status(resp1), "): ",
         tryCatch(httr2::resp_body_string(resp1), error = function(e) ""))
  }

  # Variables complexes: segona crida per respondre el sub-prompt generat
  needs_sub <- (!is.null(var_info_files) && !is.null(var_info_files$parent_prompt_val)) ||
               (!is.null(var_info_cols)  && !is.null(var_info_cols$parent_prompt_val))

  if (needs_sub) {
    sub_answers <- list()
    if (!is.null(var_info_files) && !is.null(var_info_files$parent_prompt_val)) {
      sub_answers <- c(sub_answers, list(list(
        key = paste0(var_info_files$sub_prompt_id, "@0@10"),
        values = list(var_info_files$val_str), useDefault = FALSE
      )))
    }
    if (!is.null(var_info_cols) && !is.null(var_info_cols$parent_prompt_val)) {
      sub_key_c <- paste0(var_info_cols$sub_prompt_id, "@0@10")
      if (!any(vapply(sub_answers, function(a) a$key == sub_key_c, logical(1)))) {
        sub_answers <- c(sub_answers, list(list(
          key = sub_key_c, values = list(var_info_cols$val_str),
          useDefault = FALSE
        )))
      }
    }
    if (length(sub_answers) > 0) {
      if (verbose) message("    Enviant sub-prompts...")
      resp2 <- .lab_req(url_prompts, "POST",
                        list(messageName = "", answers = sub_answers,
                             personalAnswers = list()),
                        sessio$auth_token, sessio$cookies)
      if (!httr2::resp_status(resp2) %in% c(200, 204)) {
        stop("Error enviant sub-prompts (HTTP ", httr2::resp_status(resp2), "): ",
             tryCatch(httr2::resp_body_string(resp2), error = function(e) ""))
      }
    }
  }

  if (verbose) message("    Descarregant CSV...")
  url_csv <- paste0(.LAB_BASE_URL, "/api/documents/", dossier_id,
                    "/instances/", sessio$instance_id,
                    "/visualizations/", .LAB_CONT_VIZ, "/csv")
  resp_csv <- .lab_req(url_csv, "POST", NULL,
                       sessio$auth_token, sessio$cookies, accept = "*/*")
  if (httr2::resp_status(resp_csv) != 200) {
    stop("Error descarregant CSV (HTTP ", httr2::resp_status(resp_csv), "): ",
         tryCatch(httr2::resp_body_string(resp_csv), error = function(e) ""))
  }

  df <- .lab_llegir_csv(httr2::resp_body_raw(resp_csv))

  # Mode COLS-sol: format ample -> llarg. Mode FILES+COLS: sub-capçalera.
  if (!is.null(variable_cols) && is.null(variable_files) && nrow(df) >= 2) {
    df <- .lab_cont_pivotar_cols(df)
  } else if (!is.null(variable_cols) && !is.null(variable_files) && nrow(df) >= 2) {
    df <- .lab_cont_processar_creuament(df)
  }

  .lab_cont_netejar_columnes(df)
}

.lab_cont_netejar_columnes <- function(df) {
  # Neteja final aplicada a tots els resultats:
  #   1. Elimina la columna "Metrics" (el servidor la deixa sempre buida).
  #   2. Reanomena les columnes òrfenes "...N" (el CSV porta parelles
  #      codi/etiqueta on només el codi té capçalera).
  #   3. Força els codis (territori i variable) a character.
  #   4. Homogeneïtza el nom de la columna de valors a "Contractes".
  noms_territori <- c("Municipi", "Municipis", "Comarca", "Comarques",
                      "Provincia", "Provincies",
                      "Prov\u00edncia", "Prov\u00edncies")

  if ("Metrics" %in% names(df) && all(is.na(df[["Metrics"]]))) {
    df[["Metrics"]] <- NULL
  }

  nms <- names(df)
  for (i in grep("^\\.\\.\\.\\d+$", nms)) {
    if (i == 1L) next
    left <- nms[i - 1L]
    if (left == "Mes") {
      nms[i] <- "Mes_etiqueta"
    } else if (left %in% noms_territori) {
      nms[i] <- paste0(left, "_nom")
    } else {
      nms[i]      <- left
      nms[i - 1L] <- paste0(left, "_codi")
      df[[i - 1L]] <- as.character(df[[i - 1L]])
    }
  }
  names(df) <- nms

  for (nt in intersect(noms_territori, names(df))) {
    df[[nt]] <- as.character(df[[nt]])
  }

  names(df)[names(df) %in% c("Contractes ETT", "Contractes estrangers")] <- "Contractes"

  df
}

.lab_cont_pivotar_cols <- function(df) {
  # El CSV en mode COLS té la sub-capçalera a la fila 1 de dades: NA a les
  # dims, el nom de la variable a la columna de mètrica i les categories a
  # les columnes següents. La posició de la mètrica depèn de l'àmbit, així
  # que es localitza dinàmicament. Resultat en format llarg.
  if (nrow(df) < 2) return(df)

  header_row <- as.character(unlist(df[1, ]))
  not_na_idx <- which(!is.na(header_row) & header_row != "NA" &
                        nchar(trimws(header_row)) > 0)
  if (length(not_na_idx) < 2) return(df)

  idx_var    <- not_na_idx[1]
  idx_cats   <- not_na_idx[-1]
  nom_var    <- header_row[idx_var]
  categories <- header_row[idx_cats]
  dades      <- df[-1, , drop = FALSE]
  idx_dims   <- setdiff(seq_len(ncol(df)), c(idx_var, idx_cats))

  nom_metrica <- unique(stats::na.omit(as.character(dades[[idx_var]])))
  nom_metrica <- if (length(nom_metrica) == 1) nom_metrica else "Contractes"

  resultat <- lapply(seq_along(idx_cats), function(i) {
    df_cat <- dades[, idx_dims, drop = FALSE]
    df_cat[[nom_var]]     <- categories[i]
    df_cat[[nom_metrica]] <- suppressWarnings(
      as.numeric(gsub(",", "", as.character(dades[[idx_cats[i]]])))
    )
    df_cat
  })
  out <- do.call(rbind, resultat)
  if ("Mes" %in% names(out)) out$Mes <- suppressWarnings(as.numeric(out$Mes))
  out
}

.lab_cont_processar_creuament <- function(df) {
  # Mode FILES+COLS: la fila 1 és una sub-capçalera amb el nom de la variable
  # COLS i les seves categories; les columnes de valors es reanomenen
  # Contractes_<categoria> i s'elimina la fila i la columna de mètrica.
  if (nrow(df) < 2) return(df)

  header_row <- as.character(unlist(df[1, ]))
  not_na_idx <- which(!is.na(header_row) & header_row != "NA" &
                        nchar(trimws(header_row)) > 0)
  if (length(not_na_idx) < 2) return(df)

  idx_metrics    <- not_na_idx[1]
  idx_categories <- not_na_idx[-1]
  categories     <- header_row[idx_categories]

  for (i in seq_along(idx_categories)) {
    names(df)[idx_categories[i]] <- paste0("Contractes_", categories[i])
  }

  df <- df[-1, -idx_metrics, drop = FALSE]

  if ("Mes" %in% names(df)) df$Mes <- suppressWarnings(as.numeric(df$Mes))
  for (cat in categories) {
    col_name <- paste0("Contractes_", cat)
    if (col_name %in% names(df)) {
      df[[col_name]] <- suppressWarnings(
        as.numeric(gsub(",", "", as.character(df[[col_name]])))
      )
    }
  }
  rownames(df) <- NULL
  df
}

.lab_cont_transposar_creuament <- function(df, nom_nova_col_files, nom_var_cols) {
  # Transposa el creuament quan les posicions s'han intercanviat
  # automàticament (variable només-FILES demanada a variable_cols): les
  # categories de Contractes_* passen a files i la variable de files passa a
  # columnes, amb les seves ETIQUETES com a noms.
  idx_contr <- grep("^Contractes_", names(df))
  if (length(idx_contr) == 0) return(df)
  cats_files <- sub("^Contractes_", "", names(df)[idx_contr])

  # Columna de la variable: pel nom o, si no coincideix (etiquetes internes
  # sense accents), per posició (immediatament abans del primer Contractes_).
  idx_var_col <- match(nom_var_cols, names(df))
  if (is.na(idx_var_col)) idx_var_col <- min(idx_contr) - 1L
  if (idx_var_col < 1L) return(df)
  nom_var_real <- names(df)[idx_var_col]
  idx_codi <- match(paste0(nom_var_real, "_codi"), names(df))

  idx_excl <- c(idx_contr, idx_var_col, if (!is.na(idx_codi)) idx_codi)
  idx_dims <- setdiff(seq_len(ncol(df)), idx_excl)

  vals_cols <- unique(df[[idx_var_col]])

  dim_keys <- if (length(idx_dims) > 0) {
    apply(df[, idx_dims, drop = FALSE], 1, paste, collapse = "\x01")
  } else {
    rep("", nrow(df))
  }
  unique_keys <- unique(dim_keys)

  resultat <- vector("list", length(unique_keys) * length(cats_files))
  ri <- 1L
  for (k in unique_keys) {
    mask_k   <- dim_keys == k
    df_k     <- df[mask_k, , drop = FALSE]
    dim_base <- if (length(idx_dims) > 0) df_k[1, idx_dims, drop = FALSE] else data.frame()

    for (i in seq_along(cats_files)) {
      nova_fila <- dim_base
      nova_fila[[nom_nova_col_files]] <- cats_files[i]
      col_contr <- names(df)[idx_contr[i]]
      for (v in vals_cols) {
        mask_v <- df_k[[idx_var_col]] == v
        val    <- df_k[[col_contr]][mask_v]
        nova_fila[[paste0("Contractes_", v)]] <- if (length(val)) val[1] else NA_real_
      }
      resultat[[ri]] <- nova_fila
      ri <- ri + 1L
    }
  }
  result_df <- do.call(rbind, resultat[seq_len(ri - 1L)])
  rownames(result_df) <- NULL
  result_df
}

.lab_cont_validar_params <- function(tipologia, mes, variable_files, variable_cols) {
  tipologies_valides <- c("total", "ett", "estrangeres", "estrangeres_regio")
  if (!tipologia %in% tipologies_valides) {
    stop("Tipologia '", tipologia, "' no valida. Opcions: ",
         paste(tipologies_valides, collapse = ", "))
  }
  mes_nets <- .lab_validar_mesos(mes)

  for (vnom in c(variable_files, variable_cols)) {
    if (is.null(vnom)) next
    if (!vnom %in% names(.LAB_CONT_VARIABLES)) {
      stop("Variable '", vnom, "' no reconeguda. ",
           "Usa llistar_variables_contractacio() per veure les disponibles.")
    }
    vinfo <- .LAB_CONT_VARIABLES[[vnom]]
    if (!tipologia %in% vinfo$tipologies) {
      stop("La variable '", vnom, "' no esta disponible per a '", tipologia,
           "'. Tipologies valides: ", paste(vinfo$tipologies, collapse = ", "))
    }
  }

  # Variable només-FILES demanada a variable_cols: si variable_files és
  # intercanviable, es fa el canvi automàticament i es transposa el resultat.
  swap_vars <- FALSE
  if (!is.null(variable_cols)) {
    vc <- .LAB_CONT_VARIABLES[[variable_cols]]
    if (vc$posicio == "files") {
      if (!is.null(variable_files) &&
          .LAB_CONT_VARIABLES[[variable_files]]$posicio != "cols") {
        swap_vars <- TRUE
      } else {
        stop("'", variable_cols, "' nomes pot anar a variable_files. Per ",
             "mostrar-la en columnes, especifica una variable 'ambdos' a ",
             "variable_files i la funcio intercanviara les posicions i ",
             "transposara el resultat automaticament.")
      }
    }
  }
  list(mes_nets = mes_nets, swap_vars = swap_vars)
}

# Motor comú de les quatre funcions descarrega_contractacio_*()
.lab_cont_descarrega <- function(ambit, territoris, mes, tipologia,
                                 variable_files, variable_cols, verbose,
                                 prompt_territori = NULL, obtenir_df = NULL,
                                 nom_tipus = NULL, attr_id = NULL,
                                 max_territoris_batch = 20) {
  check         <- .lab_cont_validar_params(tipologia, mes, variable_files, variable_cols)
  mes_nets      <- check$mes_nets
  var_files_api <- if (check$swap_vars) variable_cols  else variable_files
  var_cols_api  <- if (check$swap_vars) variable_files else variable_cols
  nom_col_files <- if (check$swap_vars)
    strsplit(.LAB_CONT_VARIABLES[[variable_files]]$val_str, "~")[[1]][3] else NULL
  nom_var_cols  <- if (check$swap_vars)
    strsplit(.LAB_CONT_VARIABLES[[variable_cols]]$val_str,  "~")[[1]][3] else NULL

  dossier_info <- .LAB_CONT_DOSSIERS[[tipologia]][[ambit]]
  batches_mes  <- split(mes_nets, ceiling(seq_along(mes_nets) / 12))

  sessio <- tryCatch(.lab_login(dossier_info$id, verbose),
                     error = function(e) stop("Error login: ", e$message))
  on.exit(.lab_tancar_sessio(sessio), add = TRUE)

  # Valors de territori (NULL per a Catalunya); batching de 20 en 20
  batches_terr <- list(NULL)
  if (!is.null(territoris)) {
    territoris_df <- tryCatch(obtenir_df(sessio, verbose), error = function(e) NULL)
    territori_values <- vapply(territoris, function(t) {
      if (identical(attr_id, .LAB_ATTR_MUNICIPI)) {
        .lab_match_municipi(t, territoris_df)
      } else {
        .lab_match_ambit(t, territoris_df, attr_id, nom_tipus)
      }
    }, character(1))
    batches_terr <- split(unname(territori_values),
                          ceiling(seq_along(territori_values) / max_territoris_batch))
  }

  primera   <- TRUE
  resultats <- list()

  for (bt in batches_terr) {
    for (bi in seq_along(batches_mes)) {
      batch <- batches_mes[[bi]]
      if (verbose) message("  Batch mesos ", batch[1], " - ",
                           batch[length(batch)], "...")
      if (!primera) {
        sessio <- tryCatch(.lab_nova_instancia(sessio, dossier_info$id, verbose),
                           error = function(e) NULL)
        if (is.null(sessio)) { warning("Error creant nova instancia."); next }
      }
      primera <- FALSE

      res <- tryCatch({
        r <- .lab_cont_enviar_i_descarregar(
          sessio, dossier_info$id, dossier_info$files, dossier_info$cols,
          vapply(batch, .lab_construir_mes_value, character(1)),
          bt, prompt_territori,
          var_files_api, var_cols_api, verbose
        )
        if (!is.null(nom_col_files) && !is.null(r)) {
          r <- .lab_cont_transposar_creuament(r, nom_col_files, nom_var_cols)
        }
        r
      },
      error = function(e) {
        warning("Batch [", class(e)[1], "]: ",
                tryCatch(toString(conditionMessage(e)),
                         error = function(x) class(e)[1]), call. = FALSE)
        NULL
      })
      if (!is.null(res)) resultats <- c(resultats, list(res))
    }
  }

  if (length(resultats) == 0) stop("Cap batch ha retornat dades.")
  dplyr::bind_rows(resultats)
}

#' Descarrega la contractació laboral de Catalunya
#'
#' Retorna el nombre de contractes registrats al conjunt de Catalunya per als
#' mesos indicats, per a la tipologia triada i amb desagregació opcional.
#'
#' @param mes Mes o vector de mesos en format `"AAAAMM"` (ex. `"202501"`).
#'   El batching automàtic gestiona qualsevol nombre de mesos (màxim 12 per
#'   crida a l'API).
#' @param tipologia Una de `"total"` (per defecte), `"ett"`, `"estrangeres"`
#'   o `"estrangeres_regio"`.
#' @param variable_files Clau opcional d'una variable de desagregació en
#'   files (vegeu [llistar_variables_contractacio()]).
#' @param variable_cols Clau opcional d'una variable en columnes: el resultat
#'   té una columna `Contractes_<categoria>` per categoria. Les variables amb
#'   posició `"files"` s'intercanvien i es transposen automàticament.
#' @param verbose Mostra missatges de progrés (per defecte `TRUE`).
#' @return Un `data.frame` amb les columnes `Mes` (codi, ex. `202501`),
#'   `Mes_etiqueta`, les columnes de desagregació si n'hi ha (per a les
#'   variables amb codi i etiqueta, `<variable>_codi` i `<variable>`), i la
#'   columna numèrica `Contractes` (o `Contractes_<categoria>` en
#'   creuaments). Les cel·les amb secret estadístic (`"#"`) es retornen com
#'   a `NA`.
#' @examples
#' \dontrun{
#' df <- descarrega_contractacio_catalunya(mes = "202501")
#' df <- descarrega_contractacio_catalunya(mes = "202501", tipologia = "ett",
#'                                         variable_files = "modalitat_ett")
#' df <- descarrega_contractacio_catalunya(mes = "202501",
#'                                         variable_files = "jornada",
#'                                         variable_cols  = "sexe")
#' }
#' @export
descarrega_contractacio_catalunya <- function(mes, tipologia = "total",
                                              variable_files = NULL,
                                              variable_cols  = NULL,
                                              verbose = TRUE) {
  .lab_cont_descarrega("cat", NULL, mes, tipologia,
                       variable_files, variable_cols, verbose)
}

#' Descarrega la contractació laboral per províncies
#'
#' @param provincies Vector de noms de província (`"Barcelona"`, `"Girona"`,
#'   `"Lleida"`, `"Tarragona"`) o codis INE de 2 dígits.
#' @inheritParams descarrega_contractacio_catalunya
#' @return Com [descarrega_contractacio_catalunya()], amb les columnes
#'   addicionals `Provincia` (codi, character) i `Provincia_nom`.
#' @examples
#' \dontrun{
#' df <- descarrega_contractacio_provincies("Lleida", mes = "202501")
#' }
#' @export
descarrega_contractacio_provincies <- function(provincies, mes,
                                               tipologia = "total",
                                               variable_files = NULL,
                                               variable_cols  = NULL,
                                               verbose = TRUE) {
  if (missing(provincies) || length(provincies) == 0) {
    stop("Cal especificar almenys una provincia.")
  }
  .lab_cont_descarrega("prov", provincies, mes, tipologia,
                       variable_files, variable_cols, verbose,
                       prompt_territori = .LAB_CONT_PROMPT_PROVINCIA,
                       obtenir_df = .lab_provincies,
                       nom_tipus = "la provincia", attr_id = .LAB_ATTR_PROVINCIA)
}

#' Descarrega la contractació laboral per comarques
#'
#' @param comarques Vector de noms de comarca (ex. `c("Maresme", "Bages")`)
#'   o codis de 2 dígits.
#' @inheritParams descarrega_contractacio_catalunya
#' @return Com [descarrega_contractacio_catalunya()], amb les columnes
#'   addicionals `Comarca` (codi, character) i `Comarca_nom`.
#' @examples
#' \dontrun{
#' df <- descarrega_contractacio_comarques("Maresme", mes = "202501")
#' }
#' @export
descarrega_contractacio_comarques <- function(comarques, mes,
                                              tipologia = "total",
                                              variable_files = NULL,
                                              variable_cols  = NULL,
                                              verbose = TRUE) {
  if (missing(comarques) || length(comarques) == 0) {
    stop("Cal especificar almenys una comarca.")
  }
  .lab_cont_descarrega("com", comarques, mes, tipologia,
                       variable_files, variable_cols, verbose,
                       prompt_territori = .LAB_CONT_PROMPT_COMARCA,
                       obtenir_df = .lab_comarques,
                       nom_tipus = "la comarca", attr_id = .LAB_ATTR_COMARCA)
}

#' Descarrega la contractació laboral per municipis
#'
#' @param municipis Vector de codis INE de 5 dígits (ex. `"08121"`) o noms de
#'   municipi. El batching automàtic gestiona grups de més de 20 municipis.
#' @inheritParams descarrega_contractacio_catalunya
#' @return Com [descarrega_contractacio_catalunya()], amb les columnes
#'   addicionals `Municipi` (codi INE, character) i `Municipi_nom`.
#' @section Secret estadístic:
#' En l'àmbit municipal, les cel·les amb menys de 4 contractes se suprimeixen
#' per secret estadístic i es retornen com a `NA`. Les categories amb zero
#' contractes simplement no apareixen al resultat.
#' @examples
#' \dontrun{
#' df <- descarrega_contractacio_municipis("08121", mes = "202501")
#' df <- descarrega_contractacio_municipis("08121", mes = "202501",
#'                                         variable_files = "edat_3",
#'                                         variable_cols  = "sexe")
#' }
#' @export
descarrega_contractacio_municipis <- function(municipis, mes,
                                              tipologia = "total",
                                              variable_files = NULL,
                                              variable_cols  = NULL,
                                              verbose = TRUE) {
  if (missing(municipis) || length(municipis) == 0) {
    stop("Cal especificar almenys un municipi.")
  }
  .lab_cont_descarrega("muni", municipis, mes, tipologia,
                       variable_files, variable_cols, verbose,
                       prompt_territori = .LAB_CONT_PROMPT_MUNICIPI,
                       obtenir_df = .lab_municipis,
                       nom_tipus = "el municipi", attr_id = .LAB_ATTR_MUNICIPI)
}
