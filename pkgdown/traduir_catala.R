# Tradueix al català els rètols d'interfície que pkgdown genera en anglès
# (pkgdown no té traducció catalana). Executar des de l'arrel del paquet,
# DESPRÉS de cada pkgdown::build_site():
#
#   Rscript pkgdown/traduir_catala.R

subs <- c(
  ">Skip to contents<"        = ">Vés al contingut<",
  "placeholder=\"Search for\"" = "placeholder=\"Cerca\"",
  ">Function reference<"      = ">Referència de funcions<",
  "Function reference"        = "Referència de funcions",
  ">Usage<"                   = ">Ús<",
  ">Value<"                   = ">Valor<",
  ">Details<"                 = ">Detalls<",
  ">See also<"                = ">Vegeu també<",
  ">Authors<"                 = ">Autors<",
  ">Author<"                  = ">Autor<",
  "Authors and Citation"      = "Autoria i citació",
  ">Citation<"                = ">Citació<",
  "Citing laboR"              = "Com citar laboR",
  ">Examples<"                = ">Exemples<",
  ">On this page<"            = ">En aquesta pàgina<",
  ">Links<"                   = ">Enllaços<",
  ">License<"                 = ">Llicència<",
  ">Developers<"              = ">Desenvolupadors<",
  "Browse source code"        = "Explora el codi font",
  "Report a bug"              = "Informa d'un error",
  "Full license"              = "Llicència completa",
  "All vignettes"             = "Totes les vinyetes",
  "Source: <a"                = "Codi font: <a",
  "Page not found (404)"      = "Pàgina no trobada (404)",
  ">Maintainer<"              = ">Mantenidor<",
  "<strong>Maintainer</strong>" = "<strong>Mantenidor</strong>",
  "Author, maintainer"        = "Autor, mantenidor",
  ">Changelog<"               = ">Historial de canvis<",
  "Changelog"                 = "Historial de canvis"
)

fitxers <- list.files("docs", pattern = "\\.html$",
                      recursive = TRUE, full.names = TRUE)

for (f in fitxers) {
  x <- readLines(f, encoding = "UTF-8", warn = FALSE)
  for (i in seq_along(subs)) {
    x <- gsub(names(subs)[i], subs[[i]], x, fixed = TRUE)
  }
  con <- file(f, open = "w", encoding = "UTF-8")
  writeLines(x, con)
  close(con)
}

cat("Traduïts", length(fitxers), "fitxers HTML de docs/\n")
