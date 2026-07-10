# atur.R — descàrrega de dades d'atur registrat i demandes d'ocupació.
# Un dossier per àmbit geogràfic; tots comparteixen els prompts de Mes, Sexe
# i Variables, i cada dossier territorial afegeix el seu prompt de territori.

.LAB_ATUR_VIZ <- "W23E19B6208374CB88D2D4B8E6A364C72"

.LAB_ATUR_DOSSIERS <- list(
  cat  = list(id = "B065811D654BF7F9FDB37AB5899DD19D",
              msg = "Catalunya. 2011 en endavant.",
              prompt_territori = NULL),
  com  = list(id = "A568542CC64B070B206F0089A3470613",
              msg = "Comarques i Aran. 2011 en endavant.",
              prompt_territori = "DA1ECF71E241C375DB03698FB8E65EE4@0@10"),
  prov = list(id = "BCE76821B24519B2DC43BD88330ACAB7",
              msg = "Provincies. 2011 en endavant.",
              prompt_territori = "17A6F2B32741CE49D8EE50B06ED1AC30@0@10"),
  muni = list(id = "1CF440123D4877164AF6B7B8F69BBFF6",
              msg = "Municipis. 2011 en endavant.",
              prompt_territori = "A8BF89460F4038FE2300ADBA7A79DF89@0@10")
)

.LAB_ATUR_PROMPT_MES      <- "715623DF5C44D717E68F98A8290BE2BB@0@10"
.LAB_ATUR_PROMPT_SEXE     <- "594D3E2E1A4166D64DDAD196F5B06313@0@10"
.LAB_ATUR_PROMPT_VARIABLE <- "76D037AA91415C74934C699FAF178875@0@10"

.LAB_ATUR_SEXE_VAL <- "D266E24A11D4C75E2000058EE23BF035~12~Sexe"

# Variables de desagregació (IDs d'atribut ~12~ del selector "Atributs")
.LAB_ATUR_VARIABLES <- list(
  edat         = list(val = "D266E24E11D4C75E2000058EE23BF035~12~Tram edats (11)",
                      descripcio = "Tram edats (11 grups)"),
  edat_3       = list(val = "D266E25011D4C75E2000058EE23BF035~12~Tram edats (3)",
                      descripcio = "Tram edats (3 grups)"),
  nacionalitat = list(val = "C3908B0041718A3E14AC4DAE2610D24D~12~Gran regi\u00f3 nacionalitat",
                      descripcio = "Gran regi\u00f3 nacionalitat (11 regions)"),
  ambit_nac    = list(val = "79EAAF914ACDDBF79A278C91D34CADB2~12~\u00c0mbit nacionalitat",
                      descripcio = "\u00c0mbit nacionalitat (4 grups)"),
  inscripcio   = list(val = "3F13906F11D4D01320000F8EE23BF035~12~Temps inscripci\u00f3 demanda (9 trams)",
                      descripcio = "Temps inscripci\u00f3 demanda (9 trams)"),
  formatiu     = list(val = "DB228F2140B0C524683753A8D0435D61~12~Grup nivell formatiu",
                      descripcio = "Grup nivell formatiu"),
  activitat    = list(val = "D266D34F11D4C75E2000058EE23BF035~12~Divisi\u00f3 econ\u00f2mica (CCAE 2009)",
                      descripcio = "Divisi\u00f3 econ\u00f2mica (CCAE 2009)"),
  seccio_econ  = list(val = "D266D35111D4C75E2000058EE23BF035~12~Secci\u00f3 econ\u00f2mica (CCAE 2009)",
                      descripcio = "Secci\u00f3 econ\u00f2mica (CCAE 2009)"),
  sector_econ  = list(val = "D266D35211D4C75E2000058EE23BF035~12~Sector econ\u00f2mic (CCAE 2009)",
                      descripcio = "Sector econ\u00f2mic (CCAE 2009, 4 sectors)"),
  ocupacio     = list(val = "D266D61211D4C75E2000058EE23BF035~12~Gran grup ocupaci\u00f3",
                      descripcio = "Gran grup ocupaci\u00f3 (CNO 2011)"),
  subgrup_ocp  = list(val = "D266D61711D4C75E2000058EE23BF035~12~Subgrup principal ocupaci\u00f3",
                      descripcio = "Subgrup principal ocupaci\u00f3 (CNO 2011)"),
  experiencia  = list(val = "98E810334597148164EB0189A4A154E3~12~Experi\u00e8ncia en l'ocupaci\u00f3 demandada",
                      descripcio = "Experi\u00e8ncia en l'ocupaci\u00f3 demandada (4 trams)")
)

#' Llista les variables de desagregació disponibles per a l'atur registrat
#'
#' Les funcions `descarrega_atur_*()` accepten fins a dues d'aquestes
#' variables al paràmetre `variables`; el servidor retorna el producte
#' cartesià de les seves categories.
#'
#' @return Un `data.frame` amb les columnes `clau` (el valor que es passa a
#'   `variables`) i `descripcio`.
#' @examples
#' llistar_variables_atur()
#' @export
llistar_variables_atur <- function() {
  data.frame(
    clau       = names(.LAB_ATUR_VARIABLES),
    descripcio = vapply(.LAB_ATUR_VARIABLES, function(v) v$descripcio, character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

.lab_atur_validar_variables <- function(variables) {
  if (is.null(variables) || length(variables) == 0) return(NULL)
  variables <- variables[seq_len(min(2, length(variables)))]
  no_reconegudes <- setdiff(variables, names(.LAB_ATUR_VARIABLES))
  if (length(no_reconegudes) > 0) {
    stop("Variable(s) no reconeguda(es): ",
         paste0("'", no_reconegudes, "'", collapse = ", "), ". ",
         "Usa llistar_variables_atur() per veure les disponibles.")
  }
  variables
}

# Envia les respostes als prompts d'una instància i descarrega el CSV
.lab_atur_enviar_i_descarregar <- function(
    sessio, dossier_id, msg_name,
    mes_value,
    territori_value  = NULL,
    prompt_territori = NULL,
    amb_sexe  = FALSE,
    variables = NULL,
    verbose   = FALSE
) {
  url_prompts <- paste0(.LAB_BASE_URL, "/api/documents/", dossier_id,
                        "/instances/", sessio$instance_id, "/promptsAnswers")

  answers <- list(list(key = .LAB_ATUR_PROMPT_MES,
                       values = list(mes_value), useDefault = FALSE))

  if (!is.null(territori_value) && !is.null(prompt_territori)) {
    answers <- c(answers, list(list(key = prompt_territori,
                                    values = list(territori_value),
                                    useDefault = FALSE)))
  }

  if (isTRUE(amb_sexe)) {
    answers <- c(answers, list(list(key = .LAB_ATUR_PROMPT_SEXE,
                                    values = list(.LAB_ATUR_SEXE_VAL),
                                    useDefault = FALSE)))
  } else {
    answers <- c(answers, list(list(key = .LAB_ATUR_PROMPT_SEXE,
                                    values = list(), useDefault = TRUE)))
  }

  if (!is.null(variables)) {
    var_vals <- lapply(variables, function(v) .LAB_ATUR_VARIABLES[[v]]$val)
    answers <- c(answers, list(list(key = .LAB_ATUR_PROMPT_VARIABLE,
                                    values = var_vals, useDefault = FALSE)))
  } else {
    answers <- c(answers, list(list(key = .LAB_ATUR_PROMPT_VARIABLE,
                                    values = list(), useDefault = TRUE)))
  }

  if (verbose) message("    Enviant seleccions al servidor...")
  resp <- .lab_req(url_prompts, "POST",
                   list(messageName = msg_name, answers = answers,
                        personalAnswers = list()),
                   sessio$auth_token, sessio$cookies)
  if (!httr2::resp_status(resp) %in% c(200, 204)) {
    stop("Error enviant prompts (HTTP ", httr2::resp_status(resp), "): ",
         tryCatch(httr2::resp_body_string(resp), error = function(e) ""))
  }

  if (verbose) message("    Descarregant CSV...")
  url_csv <- paste0(.LAB_BASE_URL, "/api/documents/", dossier_id,
                    "/instances/", sessio$instance_id,
                    "/visualizations/", .LAB_ATUR_VIZ, "/csv")
  resp_csv <- .lab_req(url_csv, "POST", NULL,
                       sessio$auth_token, sessio$cookies, accept = "*/*")
  if (httr2::resp_status(resp_csv) != 200) {
    stop("Error descarregant CSV (HTTP ", httr2::resp_status(resp_csv), "): ",
         tryCatch(httr2::resp_body_string(resp_csv), error = function(e) ""))
  }

  df <- .lab_llegir_csv(httr2::resp_body_raw(resp_csv))

  # Els dossiers d'àmbits superiors afegeixen una fila de "Total"
  df[is.na(df[[1]]) | df[[1]] != "Total", , drop = FALSE]
}

# Neteja final del resultat d'atur: noms de columna consistents amb el mòdul
# de contractació, codis de territori com a character i eliminació de les
# columnes completament buides (artefacte del CSV amb coma final).
.lab_atur_netejar <- function(df) {
  df <- df[, !vapply(df, function(col) all(is.na(col)), logical(1)), drop = FALSE]

  mapa <- c("Codi"             = "Mes",
            "Mes"              = "Mes_etiqueta",
            "Codi Muni."       = "Municipi",
            "Municipis"        = "Municipi_nom",
            "Codi Com."        = "Comarca",
            "Comarques i Aran" = "Comarca_nom",
            "Comarques"        = "Comarca_nom",
            "Codi Prov."       = "Provincia",
            "Prov\u00edncies"  = "Provincia_nom",
            "Provincies"       = "Provincia_nom")
  nms <- names(df)
  coincideix <- nms %in% names(mapa)
  nms[coincideix] <- unname(mapa[nms[coincideix]])
  names(df) <- nms

  for (col in intersect(c("Municipi", "Comarca", "Provincia"), names(df))) {
    df[[col]] <- as.character(df[[col]])
  }
  df
}

# Motor comú de les quatre funcions descarrega_atur_*():
# itera territori x mes (una instància nova per crida) i combina resultats.
.lab_atur_descarrega <- function(ambit, territoris, mes, amb_sexe, variables,
                                 verbose, obtenir_df, nom_tipus, attr_id) {
  mes_nets  <- .lab_validar_mesos(mes)
  variables <- .lab_atur_validar_variables(variables)
  dossier   <- .LAB_ATUR_DOSSIERS[[ambit]]

  sessio <- tryCatch(.lab_login(dossier$id, verbose),
                     error = function(e) stop("No s'ha pogut crear la sessio: ",
                                              e$message))
  on.exit(.lab_tancar_sessio(sessio), add = TRUE)
  if (verbose) message("Sessio creada. Instance ID: ", sessio$instance_id)

  # Valors de territori (NULL per a Catalunya)
  territori_values <- NULL
  if (!is.null(territoris)) {
    territoris_df <- tryCatch(obtenir_df(sessio, verbose), error = function(e) NULL)
    territori_values <- vapply(territoris, function(t) {
      if (identical(attr_id, .LAB_ATTR_MUNICIPI)) {
        .lab_match_municipi(t, territoris_df)
      } else {
        .lab_match_ambit(t, territoris_df, attr_id, nom_tipus)
      }
    }, character(1))
    if (verbose) message("Territoris identificats: ",
                         paste(territoris, collapse = ", "))
  }

  primera    <- TRUE
  resultats  <- list()
  iter_terr  <- if (is.null(territori_values)) list(NULL) else territori_values

  for (tv in iter_terr) {
    for (m in mes_nets) {
      if (verbose) message("Processant mes ", m,
                           if (!is.null(tv)) paste0(" (", sub(".*~", "", tv), ")"),
                           "...")
      if (!primera) {
        sessio <- tryCatch(.lab_nova_instancia(sessio, dossier$id, verbose),
                           error = function(e) NULL)
        if (is.null(sessio)) { warning("Error creant nova instancia."); next }
      }
      primera <- FALSE

      df <- tryCatch(
        .lab_atur_enviar_i_descarregar(
          sessio, dossier$id, dossier$msg,
          mes_value        = .lab_construir_mes_value(m),
          territori_value  = tv,
          prompt_territori = dossier$prompt_territori,
          amb_sexe         = amb_sexe,
          variables        = variables,
          verbose          = verbose
        ),
        error = function(e) { warning("Error al mes ", m, ": ", e$message,
                                      call. = FALSE); NULL }
      )
      # La neteja es fa per dataframe, abans de combinar: garanteix que els
      # codis de territori siguin character a tots (un codi sense zero
      # inicial, ex. 25120, es llegiria numeric i bind_rows() fallaria).
      if (!is.null(df)) resultats <- c(resultats, list(.lab_atur_netejar(df)))
    }
  }

  if (length(resultats) == 0) {
    stop("No s'ha pogut descarregar cap dada. Revisa els parametres i la connexio.")
  }
  df_final <- dplyr::bind_rows(resultats)
  if (verbose) message("Descarrega completada. ", nrow(df_final), " files obtingudes.")
  df_final
}

#' Descarrega l'atur registrat de Catalunya
#'
#' Retorna l'atur registrat, els demandants no ocupats i els demandants
#' d'ocupació del conjunt de Catalunya per als mesos indicats.
#'
#' @param mes Mes o vector de mesos en format `"AAAAMM"` (ex. `"202501"`).
#'   Per a un rang:
#'   `format(seq(as.Date("2024-01-01"), as.Date("2024-12-01"), by = "month"), "%Y%m")`.
#' @param amb_sexe Si `TRUE`, desagrega les dades per sexe (afegeix la columna
#'   `Sexe`). Per defecte `FALSE`.
#' @param variables Vector amb una o dues claus de variable de desagregació
#'   (vegeu [llistar_variables_atur()]). Amb dues variables el servidor
#'   retorna el producte cartesià de les categories. Per defecte `NULL`
#'   (sense desagregació).
#' @param verbose Mostra missatges de progrés (per defecte `TRUE`).
#' @return Un `data.frame` amb les columnes `Mes` (codi, ex. `202501`),
#'   `Mes_etiqueta` (ex. `"gener de 2025"`), les columnes de desagregació si
#'   n'hi ha, i les columnes numèriques `Atur registrat`,
#'   `Demandants no ocupats` i `Demandants d'ocupació`. Les cel·les amb
#'   secret estadístic (`"#"`) es retornen com a `NA`.
#' @examples
#' \dontrun{
#' df <- descarrega_atur_catalunya(mes = "202501")
#' df <- descarrega_atur_catalunya(mes = "202501", variables = "edat_3")
#' }
#' @export
descarrega_atur_catalunya <- function(mes, amb_sexe = FALSE, variables = NULL,
                                      verbose = TRUE) {
  .lab_atur_descarrega("cat", NULL, mes, amb_sexe, variables, verbose,
                       NULL, NULL, NULL)
}

#' Descarrega l'atur registrat per províncies
#'
#' @param provincies Vector de noms de província (`"Barcelona"`, `"Girona"`,
#'   `"Lleida"`, `"Tarragona"`) o codis INE de 2 dígits.
#' @inheritParams descarrega_atur_catalunya
#' @return Com [descarrega_atur_catalunya()], amb les columnes addicionals
#'   `Provincia` (codi) i `Provincia_nom`.
#' @examples
#' \dontrun{
#' df <- descarrega_atur_provincies("Barcelona", mes = "202501")
#' df <- descarrega_atur_provincies(c("Lleida", "Girona"), mes = "202501",
#'                                  variables = "nacionalitat")
#' }
#' @export
descarrega_atur_provincies <- function(provincies, mes, amb_sexe = FALSE,
                                       variables = NULL, verbose = TRUE) {
  if (missing(provincies) || length(provincies) == 0) {
    stop("Cal especificar almenys una provincia.")
  }
  .lab_atur_descarrega("prov", provincies, mes, amb_sexe, variables, verbose,
                       .lab_provincies, "la provincia", .LAB_ATTR_PROVINCIA)
}

#' Descarrega l'atur registrat per comarques
#'
#' @param comarques Vector de noms de comarca (ex. `c("Maresme", "Bages")`)
#'   o codis de 2 dígits.
#' @inheritParams descarrega_atur_catalunya
#' @return Com [descarrega_atur_catalunya()], amb les columnes addicionals
#'   `Comarca` (codi) i `Comarca_nom`.
#' @examples
#' \dontrun{
#' df <- descarrega_atur_comarques("Maresme", mes = "202501")
#' }
#' @export
descarrega_atur_comarques <- function(comarques, mes, amb_sexe = FALSE,
                                      variables = NULL, verbose = TRUE) {
  if (missing(comarques) || length(comarques) == 0) {
    stop("Cal especificar almenys una comarca.")
  }
  .lab_atur_descarrega("com", comarques, mes, amb_sexe, variables, verbose,
                       .lab_comarques, "la comarca", .LAB_ATTR_COMARCA)
}

#' Descarrega l'atur registrat per municipis
#'
#' @param municipis Vector de codis INE de 5 dígits (ex. `"08121"`) o noms de
#'   municipi (ex. `"Mataró"`). El codi INE és més robust; el nom ha de
#'   coincidir amb el registre del servidor (vegeu [obtenir_municipis()]).
#' @inheritParams descarrega_atur_catalunya
#' @return Com [descarrega_atur_catalunya()], amb les columnes addicionals
#'   `Municipi` (codi INE, character) i `Municipi_nom`.
#' @section Secret estadístic:
#' En municipis de menys de 20.000 habitants, les cel·les amb valors d'1 a 3
#' se suprimeixen per secret estadístic i es retornen com a `NA`.
#' @examples
#' \dontrun{
#' df <- descarrega_atur_municipis("08121", mes = "202501")
#' df <- descarrega_atur_municipis(c("08121", "08019"), mes = "202501",
#'                                 amb_sexe = TRUE, variables = "edat_3")
#' }
#' @export
descarrega_atur_municipis <- function(municipis, mes, amb_sexe = FALSE,
                                      variables = NULL, verbose = TRUE) {
  if (missing(municipis) || length(municipis) == 0) {
    stop("Cal especificar almenys un municipi (codi INE o nom).")
  }
  .lab_atur_descarrega("muni", municipis, mes, amb_sexe, variables, verbose,
                       .lab_municipis, "el municipi", .LAB_ATTR_MUNICIPI)
}
