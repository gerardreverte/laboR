# zzz.R — comprovació de compatibilitat entre httr2 i curl.
#
# httr2 declara a la seva DESCRIPTION la versió mínima de curl que necessita
# (p. ex. httr2 1.2.x requereix curl >= 6.4.0), però R no verifica aquesta
# coherència en carregar els paquets: una biblioteca amb httr2 modern i curl
# antic conviu silenciosament i peta a la primera petició amb l'error críptic
# "`method` must be a single string, not `NULL`". Aquí ho detectem i ho
# expliquem clarament.

.lab_versions_incompatibles <- function() {
  imports <- utils::packageDescription("httr2")$Imports
  if (is.null(imports)) return(NULL)
  m <- regmatches(imports, regexec("curl \\(>= ([0-9.\\-]+)\\)", imports))[[1]]
  if (length(m) < 2) return(NULL)
  minim  <- m[2]
  actual <- utils::packageVersion("curl")
  if (actual < minim) {
    list(actual = as.character(actual), minim = minim)
  } else {
    NULL
  }
}

.lab_missatge_incompatibilitat <- function(inc) {
  paste0(
    "La versio instal·lada del paquet 'curl' (", inc$actual,
    ") es mes antiga que la que requereix la teva versio d'httr2 ",
    "(cal curl >= ", inc$minim, "), i les connexions fallarien. ",
    "Actualitza els dos paquets amb:\n",
    "  install.packages(c(\"curl\", \"httr2\"))\n",
    "i reinicia la sessio d'R."
  )
}

.onAttach <- function(libname, pkgname) {
  inc <- tryCatch(.lab_versions_incompatibles(), error = function(e) NULL)
  if (!is.null(inc)) {
    packageStartupMessage("AVIS (laboR): ", .lab_missatge_incompatibilitat(inc))
  }
}
