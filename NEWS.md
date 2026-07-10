# laboR 0.1.1

* En carregar el paquet i abans de cada connexió es comprova que les
  versions dels paquets `curl` i `httr2` siguin compatibles entre elles.
  Si no ho són (httr2 modern amb un curl massa antic), ara s'obté un
  missatge clar amb la solució (`install.packages(c("curl", "httr2"))`)
  en lloc de l'error críptic ``  `method` must be a single string, not
  `NULL` `` en intentar la primera descàrrega.

# laboR 0.1.0

* Versió inicial del paquet: descàrrega d'atur registrat, demandants
  d'ocupació i contractació laboral de l'Observatori del Treball i Model
  Productiu (Generalitat de Catalunya), per a Catalunya, províncies,
  comarques i municipis, amb sèries mensuals des del gener de 2011.
