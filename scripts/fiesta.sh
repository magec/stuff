#!/bin/bash
# http://cv.uoc.edu/UOC/a/intrauoc/calendaribcn.htm
# http://cv.uoc.edu/UOC/a/intrauoc/js/calendaribcn.js
FIESTA=(07/04/09 01/01/09 06/01/09 10/04/09 09/04/09 13/04/09 23/04/09 01/05/09 01/07/09 24/07/09 15/08/09 11/09/09 24/09/09 12/10/09 01/11/09 06/12/09 08/12/09 24/12/09 25/12/09 26/12/09 31/12/09)
[[ ( $(date +%u) -gt 5 ) && ( ${FIESTA[*]} =~ $(date +%D) ) ]] && { echo "Festivo!" ; exit 0 ; } || exit 1
