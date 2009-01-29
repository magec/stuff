#!/bin/bash
. tren.env

#firefox "http://cv.uoc.edu/tren/trenacc?s=$(sessio_tren)&modul=RUC.RESOLUCION_PETICION/buscarPeticions.do&subaccio=iniciar&entidad_gestora=GOT"
firefox "http://cv.uoc.edu/tren/trenacc?s=$(sessio_tren)&modul=RUC.RESOLUCION_PETICION/buscarPeticions.do&subaccio=iniciar&entidad_gestora=GOT&assignadasSelec=Peticions assignades"
