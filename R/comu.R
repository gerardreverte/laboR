# comu.R — infraestructura compartida entre els mòduls d'atur i contractació:
# sessions MicroStrategy, lectura de CSV, mesos i llistes de territori.
# Les funcions amb prefix .lab_ són internes i no s'exporten.

.LAB_BASE_URL   <- "https://observatorideltreball.gencat.cat/OTMP"
.LAB_PROJECT_ID <- "8FA813EA47B9B85AEDA6E1831720251A"

# Atributs de dimensió compartits per tots els dossiers (atur i contractació)
.LAB_ATTR_MES       <- "D266CB2011D4C75E2000058EE23BF035"
.LAB_ATTR_MUNICIPI  <- "D266CF0711D4C75E2000058EE23BF035"
.LAB_ATTR_COMARCA   <- "58D1BF3045C2121B08AE9B8D3211C8A7"
.LAB_ATTR_PROVINCIA <- "D266CF0911D4C75E2000058EE23BF035"

# Dossier usat per crear sessions quan només cal consultar atributs
.LAB_DOSSIER_SESSIO <- "1CF440123D4877164AF6B7B8F69BBFF6"

`%||%` <- function(a, b) if (!is.null(a)) a else b


# peticions HTTP i gestió de sessió -------------------------------------------

.lab_extraure_cookies <- function(resp) {
  # El servidor retorna iSession, JSESSIONID i MSTRDEVICEID via Set-Cookie.
  # Cal enviar-les totes a les crides posteriors.
  hdrs        <- httr2::resp_headers(resp)
  hdr_names   <- tolower(names(hdrs))
  cookie_vals <- unlist(hdrs[hdr_names == "set-cookie"])
  paste(sub(";.*", "", cookie_vals), collapse = "; ")
}

.lab_req <- function(url, method = "GET", body = NULL,
                     auth_token, cookies_str,
                     accept = "application/json") {
  # Wrapper que afegeix sempre les capçaleres d'autenticació MicroStrategy.
  r <- httr2::request(url) |>
    httr2::req_headers(
      "Accept"           = accept,
      "Content-Type"     = "application/json",
      "X-MSTR-AuthToken" = auth_token,
      "X-MSTR-ProjectID" = .LAB_PROJECT_ID,
      "X-Requested-With" = "XMLHttpRequest",
      "Cookie"           = cookies_str
    )
  if (!is.null(body))  r <- r |> httr2::req_body_json(body)
  if (method != "GET") r <- r |> httr2::req_method(method)
  r |> httr2::req_error(is_error = function(x) FALSE) |> httr2::req_perform()
}

.lab_login <- function(dossier_id, verbose = FALSE) {
  # Login anònim (loginMode=8), captura de cookies i creació de la instància
  # del dossier. Retorna: list(auth_token, instance_id, cookies)
  inc <- tryCatch(.lab_versions_incompatibles(), error = function(e) NULL)
  if (!is.null(inc)) stop(.lab_missatge_incompatibilitat(inc), call. = FALSE)

  if (verbose) message("Fent login anonim a MicroStrategy (loginMode=8)...")

  resp_login <- httr2::request(paste0(.LAB_BASE_URL, "/api/auth/login")) |>
    httr2::req_headers("Accept" = "application/json",
                       "Content-Type" = "application/json") |>
    httr2::req_body_json(list(loginMode = 8)) |>
    httr2::req_error(is_error = function(r) FALSE) |>
    httr2::req_perform()

  if (!httr2::resp_status(resp_login) %in% c(200, 204)) {
    stop("Error en login (HTTP ", httr2::resp_status(resp_login), "): ",
         tryCatch(httr2::resp_body_string(resp_login), error = function(e) ""),
         "\nL'estructura del servidor de l'Observatori pot haver canviat.")
  }

  auth_token  <- httr2::resp_header(resp_login, "X-MSTR-AuthToken")
  cookies_str <- .lab_extraure_cookies(resp_login)
  if (is.null(auth_token)) stop("El servidor no ha retornat X-MSTR-AuthToken.")

  if (verbose) message("Token obtingut. Creant instancia del dossier...")

  resp_inst <- .lab_req(
    paste0(.LAB_BASE_URL, "/api/dossiers/", dossier_id, "/instances"),
    "POST", list(disableManipulations = FALSE, persistViewState = TRUE),
    auth_token, cookies_str
  )
  if (!httr2::resp_status(resp_inst) %in% c(200, 201)) {
    stop("Error creant instancia (HTTP ", httr2::resp_status(resp_inst), "): ",
         tryCatch(httr2::resp_body_string(resp_inst), error = function(e) ""))
  }

  body        <- httr2::resp_body_json(resp_inst)
  instance_id <- body$mid %||% body$instanceId
  if (is.null(instance_id)) stop("Instancia sense ID.")

  list(auth_token = auth_token, instance_id = instance_id, cookies = cookies_str)
}

.lab_nova_instancia <- function(sessio, dossier_id, verbose = FALSE) {
  # Un cop els prompts d'una instància queden "tancats" (closed: true) el
  # servidor ignora noves respostes: cal una instància nova per a cada crida.
  resp_inst <- .lab_req(
    paste0(.LAB_BASE_URL, "/api/dossiers/", dossier_id, "/instances"),
    "POST", list(disableManipulations = FALSE, persistViewState = TRUE),
    sessio$auth_token, sessio$cookies
  )
  if (!httr2::resp_status(resp_inst) %in% c(200, 201)) {
    stop("Error creant nova instancia (HTTP ", httr2::resp_status(resp_inst), "): ",
         tryCatch(httr2::resp_body_string(resp_inst), error = function(e) ""))
  }
  body        <- httr2::resp_body_json(resp_inst)
  instance_id <- body$mid %||% body$instanceId
  if (is.null(instance_id)) stop("Nova instancia sense ID.")
  modifyList(sessio, list(instance_id = instance_id))
}

.lab_tancar_sessio <- function(sessio) {
  # Tancament silenciós (no propaga errors). Usar exclusivament amb on.exit().
  if (is.null(sessio) || is.null(sessio$auth_token)) return(invisible(NULL))
  tryCatch(
    httr2::request(paste0(.LAB_BASE_URL, "/api/auth/logout")) |>
      httr2::req_method("DELETE") |>
      httr2::req_headers("X-MSTR-AuthToken" = sessio$auth_token,
                         "X-Requested-With" = "XMLHttpRequest",
                         "Cookie"           = sessio$cookies) |>
      httr2::req_error(is_error = function(r) FALSE) |>
      httr2::req_perform(),
    error = function(e) invisible(NULL)
  )
  invisible(NULL)
}


# lectura del CSV del servidor -------------------------------------------------

.lab_llegir_csv <- function(raw_bytes) {
  # El servidor retorna UTF-16 LE amb BOM (FF FE); detectem l'encoding.
  # La coma és separador de milers (ex. "6,131" = 6131 persones).
  # "#" = secret estadístic (cel·les amb valor < 4 en municipis petits);
  # es tracta com a NA perquè les columnes de valors siguin sempre numèriques.
  if (length(raw_bytes) == 0) stop("El servidor ha retornat un CSV buit.")

  tmp_csv <- tempfile(fileext = ".csv")
  writeBin(raw_bytes, tmp_csv)
  on.exit(unlink(tmp_csv), add = TRUE)

  has_bom  <- length(raw_bytes) >= 2 && raw_bytes[1] == 0xFF && raw_bytes[2] == 0xFE
  encoding <- if (has_bom) "UTF-16LE" else "UTF-8"

  df <- suppressMessages(readr::read_csv(
    tmp_csv, show_col_types = FALSE,
    na = c("", "NA", "#"),
    locale = readr::locale(encoding = encoding,
                           decimal_mark = ".", grouping_mark = ",")
  ))
  if (nrow(df) == 0) stop("El CSV no conte dades (0 files).")
  df
}


# mesos -------------------------------------------------------------------------

.lab_format_mes_catala <- function(codi_aaaamm) {
  # Converteix "202501" en "gener de 2025"
  mesos_cat <- c("gener", "febrer", "mar\u00e7", "abril", "maig", "juny",
                 "juliol", "agost", "setembre", "octubre", "novembre", "desembre")
  any <- substr(codi_aaaamm, 1, 4)
  mes <- as.integer(substr(codi_aaaamm, 5, 6))
  paste0(mesos_cat[mes], " de ", any)
}

.lab_validar_mesos <- function(mes) {
  if (is.null(mes) || length(mes) == 0) {
    stop("Cal especificar almenys un mes en format AAAAMM (ex. '202501').")
  }
  mes_nets <- gsub("[^0-9]", "", as.character(mes))
  invalids <- mes_nets[nchar(mes_nets) != 6]
  if (length(invalids) > 0) {
    stop("Format de mes invalid: ", paste(invalids, collapse = ", "),
         ". Utilitza AAAAMM (ex. '202501').")
  }
  mes_nets
}

.lab_construir_mes_value <- function(mes_codi) {
  # Format del servidor: "{ATTR_ID}:{AAAAMM}~1048576~{etiqueta}"
  # Nota: l'etiqueta del mes de març porta ç; el servidor de contractació
  # l'accepta sense ç i el d'atur amb ç — totes dues formes funcionen perquè
  # el servidor identifica l'element pel codi AAAAMM.
  mes_codi <- gsub("[^0-9]", "", mes_codi)
  if (nchar(mes_codi) != 6) {
    stop("Format de mes no reconegut: '", mes_codi,
         "'. Utilitza AAAAMM (ex. '202501').")
  }
  paste0(.LAB_ATTR_MES, ":", mes_codi, "~1048576~", .lab_format_mes_catala(mes_codi))
}

#' Llista els mesos disponibles
#'
#' Genera la llista de mesos amb dades potencialment disponibles a
#' l'Observatori del Treball: sèrie mensual des del gener de 2011 fins al mes
#' anterior a l'actual. Els mesos més recents poden no estar publicats encara
#' (les dades es publiquen amb un cert decalatge).
#'
#' @return Un `data.frame` amb les columnes `codi_mes` (format `"AAAAMM"`,
#'   ex. `"202501"`) i `etiqueta` (ex. `"gener de 2025"`).
#' @examples
#' mesos <- llistar_mesos()
#' tail(mesos)
#' @export
llistar_mesos <- function() {
  any_inici <- 2011
  any_fi    <- as.integer(format(Sys.Date(), "%Y"))
  mes_fi    <- as.integer(format(Sys.Date(), "%m")) - 1L
  if (mes_fi == 0L) { mes_fi <- 12L; any_fi <- any_fi - 1L }

  mesos <- character(0)
  for (a in any_inici:any_fi) {
    for (m in 1:12) {
      if (a == any_fi && m > mes_fi) break
      mesos <- c(mesos, sprintf("%04d%02d", a, m))
    }
  }
  data.frame(codi_mes = mesos,
             etiqueta = vapply(mesos, .lab_format_mes_catala, character(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}


# llistes de territori ----------------------------------------------------------
# Els atributs de territori són compartits per tots els dossiers (atur i
# contractació), així que una sola família de funcions serveix per als dos
# mòduls. Les versions .lab_* reutilitzen una sessió existent; les exportades
# creen la seva pròpia sessió.

.lab_obtenir_elements <- function(sessio, attr_id, limit) {
  resp <- .lab_req(paste0(.LAB_BASE_URL, "/api/attributes/", attr_id,
                          "/elements?limit=", limit),
                   "GET", NULL, sessio$auth_token, sessio$cookies)
  if (httr2::resp_status(resp) != 200) return(NULL)
  elems <- tryCatch(
    jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = TRUE),
    error = function(e) NULL
  )
  if (is.null(elems) || nrow(elems) == 0) return(NULL)
  elems
}

.lab_territori_value <- function(attr_id, id_intern, nom) {
  paste0(attr_id, ":", id_intern, "~1048576~", nom)
}

.lab_municipis <- function(sessio, verbose = FALSE) {
  if (verbose) message("Obtenint llista de municipis...")
  # limit=10000: l'atribut conté els ~8.400 municipis de tota Espanya, però
  # els dossiers de l'Observatori només tenen dades per als catalans
  # (províncies 08, 17, 25 i 43), així que filtrem la resta.
  elems <- .lab_obtenir_elements(sessio, .LAB_ATTR_MUNICIPI, 10000)
  if (is.null(elems)) return(NULL)
  elems <- elems[grepl("^(08|17|25|43)\\d{3}:", elems$name), ]
  if (nrow(elems) == 0) return(NULL)

  id_intern <- sub("^h([^;]+);;.*", "\\1", elems$id)
  nom       <- sub("^\\d{5}:(.*)", "\\1", elems$name)
  codi_ine  <- sub("^(\\d{5}):.*", "\\1", elems$name)

  data.frame(codi_ine = codi_ine, nom = nom, id_intern = id_intern,
             value_str = .lab_territori_value(.LAB_ATTR_MUNICIPI, id_intern, nom),
             stringsAsFactors = FALSE, row.names = NULL)
}

.lab_ambit <- function(sessio, attr_id, filtre, verbose = FALSE, nom_tipus = "") {
  if (verbose) message("Obtenint llista de ", nom_tipus, "...")
  elems <- .lab_obtenir_elements(sessio, attr_id, 1000)
  if (is.null(elems)) return(NULL)
  elems <- elems[grepl(filtre, elems$name), ]
  if (nrow(elems) == 0) return(NULL)

  id_intern <- sub("^h([^;]+);;.*", "\\1", elems$id)
  nom       <- sub("^[^:]+:(.*)",   "\\1", elems$name)
  codi      <- sub("^([^:]+):.*",   "\\1", elems$name)

  data.frame(codi = codi, nom = nom, id_intern = id_intern,
             value_str = .lab_territori_value(attr_id, id_intern, nom),
             stringsAsFactors = FALSE, row.names = NULL)
}

.lab_comarques <- function(sessio, verbose = FALSE) {
  # Codis 01-43: les 43 comarques catalanes (incl. Aran, Moianès i Lluçanès).
  # L'atribut també conté pseudo-entrades tècniques (88:No consta,
  # 99:Sense especificar comarca, AL:Altres, NP, NR) que es descarten.
  .lab_ambit(sessio, .LAB_ATTR_COMARCA, "^(0[1-9]|[1-3][0-9]|4[0-3]):",
             verbose, "comarques")
}

.lab_provincies <- function(sessio, verbose = FALSE) {
  # Codis 08/17/25/43: les 4 províncies catalanes. L'atribut conté les 52
  # d'Espanya i pseudo-entrades (60:Total d'Espanya, 79:Catalunya...).
  .lab_ambit(sessio, .LAB_ATTR_PROVINCIA, "^(08|17|25|43):",
             verbose, "provincies")
}

#' Llista els municipis catalans disponibles
#'
#' Consulta el servidor de l'Observatori i retorna la llista de municipis
#' catalans (províncies de Barcelona, Girona, Lleida i Tarragona). La llista
#' inclou alguns municipis extingits per fusions recents, amb el seu codi INE
#' històric, perquè les sèries antigues poden tenir-hi dades.
#'
#' @param verbose Mostra missatges de progrés (per defecte `FALSE`).
#' @return Un `data.frame` amb les columnes `codi_ine` (5 dígits), `nom`,
#'   `id_intern` i `value_str`, o `NULL` si el servidor no respon.
#' @examples
#' \dontrun{
#' municipis <- obtenir_municipis()
#' municipis[grepl("Matar", municipis$nom), ]
#' }
#' @export
obtenir_municipis <- function(verbose = FALSE) {
  sessio <- .lab_login(.LAB_DOSSIER_SESSIO, verbose)
  on.exit(.lab_tancar_sessio(sessio), add = TRUE)
  .lab_municipis(sessio, verbose)
}

#' Llista les comarques catalanes disponibles
#'
#' @inheritParams obtenir_municipis
#' @return Un `data.frame` amb les columnes `codi`, `nom`, `id_intern` i
#'   `value_str` per a les 43 comarques catalanes (incloent-hi l'Aran, el
#'   Moianès i el Lluçanès), o `NULL` si el servidor no respon.
#' @examples
#' \dontrun{
#' comarques <- obtenir_comarques()
#' }
#' @export
obtenir_comarques <- function(verbose = FALSE) {
  sessio <- .lab_login(.LAB_DOSSIER_SESSIO, verbose)
  on.exit(.lab_tancar_sessio(sessio), add = TRUE)
  .lab_comarques(sessio, verbose)
}

#' Llista les províncies catalanes disponibles
#'
#' @inheritParams obtenir_municipis
#' @return Un `data.frame` amb les columnes `codi`, `nom`, `id_intern` i
#'   `value_str` per a les 4 províncies catalanes, o `NULL` si el servidor
#'   no respon.
#' @examples
#' \dontrun{
#' provincies <- obtenir_provincies()
#' }
#' @export
obtenir_provincies <- function(verbose = FALSE) {
  sessio <- .lab_login(.LAB_DOSSIER_SESSIO, verbose)
  on.exit(.lab_tancar_sessio(sessio), add = TRUE)
  .lab_provincies(sessio, verbose)
}


# cerca de territoris (compartida pels dos mòduls) -----------------------------

.lab_match_municipi <- function(m, municipis_df) {
  if (!is.null(municipis_df)) {
    if (grepl("^\\d{5}$", m)) {
      idx <- which(municipis_df$codi_ine == m)
    } else {
      idx <- which(tolower(municipis_df$nom) == tolower(m))
      if (!length(idx)) idx <- grep(tolower(m), tolower(municipis_df$nom))
    }
    if (length(idx)) return(municipis_df$value_str[idx[1]])
  }
  # Fallback sense llista: el codi intern MicroStrategy és el codi INE + "0"
  if (grepl("^\\d{5}$", m)) {
    return(.lab_territori_value(.LAB_ATTR_MUNICIPI, paste0(m, "0"), m))
  }
  stop("No s'ha pogut identificar el municipi '", m,
       "'. Proveeix el codi INE de 5 digits (ex. '08121') o el nom exacte.")
}

.lab_match_ambit <- function(nom, ambit_df, attr_id, nom_tipus) {
  if (!is.null(ambit_df)) {
    idx <- which(tolower(ambit_df$nom) == tolower(nom))
    if (!length(idx)) idx <- grep(tolower(nom), tolower(ambit_df$nom))
    if (length(idx)) return(ambit_df$value_str[idx[1]])
  }
  if (grepl("^\\d+$", nom)) return(.lab_territori_value(attr_id, nom, nom))
  stop("No s'ha pogut identificar ", nom_tipus, " '", nom,
       "'. Proveeix el nom exacte tal com apareix a obtenir_",
       sub("la |el ", "", nom_tipus), "().")
}
