! --------------------------------------------------------------------
! Copyright (C) 1991 - 2017 - EDF R&D - www.code-aster.org
! This file is part of code_aster.
!
! code_aster is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! code_aster is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with code_aster.  If not, see <http://www.gnu.org/licenses/>.
! --------------------------------------------------------------------

subroutine irch19(cham19, form, ifi, titre,&
                  nomsd, nomsym, numord, lcor, nbnot,&
                  numnoe, nbmat, nummai, nbcmp, nomcmp,&
                  lsup, borsup, linf, borinf, lmax,&
                  lmin, lresu, formr)
! person_in_charge: nicolas.sellenet at edf.fr
! ----------------------------------------------------------------------
!     IMPRIMER UN CHAMP (CHAM_NO OU CHAM_ELEM)
!
! IN  CHAM19: NOM DU CHAM_XX
! IN  FORM  : FORMAT :'RESULTAT' OU 'SUPERTAB'
! IN  IFI   : UNITE LOGIQUE D'IMPRESSION DU CHAMP.
! IN  TITRE : TITRE.
! IN  NOMO  : NOM DU MODELE SUPPORT.
! IN  NOMSD : NOM DU RESULTAT D'OU PROVIENT LE CHAMP A IMPRIMER.
! IN  NOMSYM: NOM SYMBOLIQUE DU CHAMP A IMPRIMER
! IN  NUMORD: NUMERO D'ORDRE DU CHAMP DANS LE RESULTAT_COMPOSE.
!             (1 SI LE RESULTAT EST UN CHAM_GD)
! IN  LCOR  : IMPRESSION DES COORDONNEES DE NOEUDS .TRUE. IMPRESSION
! IN  NBNOT : NOMBRE DE NOEUDS A IMPRIMER
! IN  NUMNOE: NUMEROS DES NOEUDS A IMPRIMER
! IN  NBMAT : NOMBRE DE MAILLES A IMPRIMER
! IN  NUMMAI: NUMEROS DES MAILLES A IMPRIMER
! IN  NBCMP : NOMBRE DE COMPOSANTES A IMPRIMER
! IN  NOMCMP: NOMS DES COMPOSANTES A IMPRIMER
! IN  LSUP  : =.TRUE. INDIQUE PRESENCE D'UNE BORNE SUPERIEURE
! IN  BORSUP: VALEUR DE LA BORNE SUPERIEURE
! IN  LINF  : =.TRUE. INDIQUE PRESENCE D'UNE BORNE INFERIEURE
! IN  BORINF: VALEUR DE LA BORNE INFERIEURE
! IN  LMAX  : =.TRUE. INDIQUE IMPRESSION VALEUR MAXIMALE
! IN  LMIN  : =.TRUE. INDIQUE IMPRESSION VALEUR MINIMALE
! IN  LRESU : =.TRUE. INDIQUE IMPRESSION D'UN CONCEPT RESULTAT
! IN  FORMR : FORMAT D'ECRITURE DES REELS SUR "RESULTAT"
! ----------------------------------------------------------------------
!
! aslint: disable=W1306,W1504
    implicit none
!
! 0.1. ==> ARGUMENTS
!
!
#include "asterf_types.h"
#include "asterfort/dismoi.h"
#include "asterfort/irchml.h"
#include "asterfort/irdepl.h"
#include "asterfort/utcmp3.h"
#include "asterfort/utmess.h"
    character(len=*) :: cham19, nomsd, nomsym
    character(len=*) :: form, formr, titre, nomcmp(*)
    real(kind=8) :: borsup, borinf
    integer :: numord, nbmat
    integer :: nbnot, numnoe(*), nummai(*), nbcmp, ncmp
    aster_logical :: lcor, lsup, linf, lmax, lmin, lresu
!
! 0.3. ==> VARIABLES LOCALES
!
!
    character(len=8) :: tych, nomgd, nomsd8
    character(len=19) :: ch19
    character(len=24) :: valk(2), tyres
    integer :: ifi, numcmp(nbcmp)
!
!     PASSAGE DANS DES VARIABLES FIXES
!
    ch19 = cham19
    nomsd8 = nomsd
!
!     --- TYPE DU CHAMP A IMPRIMER (CHAM_NO OU CHAM_ELEM)
    call dismoi('TYPE_CHAMP', ch19, 'CHAMP', repk=tych)
    call dismoi('TYPE_RESU', nomsd8, 'RESULTAT', repk=tyres)
!
    if ((tych(1:4).eq.'NOEU') .or. (tych(1:2).eq.'EL')) then
    else if (tych(1:4).eq. 'CART') then
        if ( .not. lresu ) then
            call utmess('A', 'PREPOST_92')
            goto 999
        endif
    else
        valk(1) = tych
        valk(2) = ch19
        if (tyres(1:9) .eq. 'MODE_GENE' .or. tyres(1:9) .eq. 'HARM_GENE') then
            call utmess('A+', 'PREPOST_87', nk=2, valk=valk)
            call utmess('A', 'PREPOST6_36')
        else
            call utmess('A', 'PREPOST_87', nk=2, valk=valk)
        endif
    endif
!
!     --- NOM DE LA GRANDEUR ASSOCIEE AU CHAMP CH19
    call dismoi('NOM_GD', ch19, 'CHAMP', repk=nomgd)
!
    ncmp = 0
    if (nbcmp .ne. 0) then
        if ((nomgd.eq.'VARI_R') .and. (tych(1:2).eq.'EL')) then
! --------- TRAITEMENT SUR LES "NOMCMP"
            ncmp = nbcmp
            call utcmp3(nbcmp, nomcmp, numcmp)
        endif
    endif
!
!     -- ON LANCE L'IMPRESSION:
!     -------------------------
!
    if (tych(1:4) .eq. 'NOEU' .and. nbnot .ge. 0) then
        call irdepl(ch19, ifi, form, titre,&
                    nomsd, nomsym, numord, lcor, nbnot,&
                    numnoe, nbcmp, nomcmp, lsup, borsup,&
                    linf, borinf, lmax, lmin, lresu,&
                    formr)
    else if (tych(1:2).eq.'EL'.and.nbmat.ge.0) then
        call irchml(ch19, ifi, form, titre,&
                    tych(1:4), nomsd, nomsym, numord, lcor,&
                    nbnot, numnoe, nbmat, nummai, nbcmp,&
                    nomcmp, lsup, borsup, linf, borinf,&
                    lmax, lmin, formr, ncmp,&
                    numcmp)
    endif
999 continue
!
!
end subroutine
