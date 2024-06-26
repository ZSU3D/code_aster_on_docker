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

subroutine op0181()
    implicit none
!     REALISATION N.GREFFET
!     OPERATEUR "REST_SPEC_TEMP"
!     ------------------------------------------------------------------
#include "jeveux.h"
#include "asterc/getres.h"
#include "asterfort/gettco.h"
#include "asterfort/ecresu.h"
#include "asterfort/getvid.h"
#include "asterfort/getvtx.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jemarq.h"
#include "asterfort/prefft.h"
#include "asterfort/rsexch.h"
#include "asterfort/utmess.h"
    integer :: nbva, nval, nsens, ngrand, i, ier, ngran0
    character(len=4) :: grand(3), grand0(3), cham
    character(len=16) :: type, cmd, symetr, method
    character(len=19) :: resin, resou, vectot, k19bid
    character(len=24) :: typres
    character(len=12) :: bl11pt
    integer :: iret, igrand
!     ------------------------------------------------------------------
    call jemarq()
    call getres(resou, type, cmd)
!
!     --- RECUPERATION DES ARGUMENTS UTILISATEUR
!
!     --- CAS D'UN CONCEPT SD_RESULTAT ENTRANT (BASE PHYS)
    call getvid(' ', 'RESULTAT', scal=resin, nbret=nval)
    if (nval .eq. 0) then
!        --- CAS D'UN CONCEPT SD_DYNA_GENE ENTRANT (BASE GENE)
        call getvid(' ', 'RESU_GENE', scal=resin, nbret=nval)
    endif
    call getvtx(' ', 'METHODE', scal=method, nbret=nval)
    call getvtx(' ', 'SYMETRIE', scal=symetr, nbret=nval)
!
!     --- EVALUATION DU SENS DE LA FFT
    call gettco(resin, typres)
    if ((typres(1:10).eq.'DYNA_HARMO') .or. (typres(1:9).eq.'HARM_GENE')) then
        nsens = -1
    else
        nsens = 1
    endif
!
!     --- RECUPERER LA LISTE DES CHAMPS RENSEIGNEE
    call getvtx(' ', 'NOM_CHAM', nbval=3, vect=grand0, nbret=ngran0)
!     --- CAS DE TOUT_CHAMP='OUI'
    if (ngran0 .eq. 0) then
        ngran0 = 3
        grand0(1) = 'DEPL'
        grand0(2) = 'VITE'
        grand0(3) = 'ACCE'
    endif
!     --- POUR LES CAS HARMONIQUES, IL FAUT VERIFIER QUE
!         LES CHAMPS A RESTITUER EXISTENT REELEMENT DANS
!         LA SD_RESULTANT ENTRANTE
    ngrand = 0
!               12345678901.
    bl11pt = '           .'
    do 5, igrand=1,ngran0
    cham = grand0(igrand)
    if (typres(1:9) .eq. 'HARM_GENE') then
!
        call jeexin(resin(1:8)//bl11pt//cham, iret)
        if (iret .ne. 0) then
            grand(ngrand+1)=cham
            ngrand = ngrand + 1
        endif
!
    else if (typres(1:10).eq.'DYNA_HARMO') then
!
        call rsexch(' ', resin(1:8), cham, 1, k19bid,&
                    iret)
        if (iret .eq. 0) then
            grand(ngrand+1)=cham
            ngrand = ngrand + 1
        endif
!
    else
!       --- CAS DES SD TRANSITOIRES => LES 3 CHAMPS EXISTENT
!
        grand(ngrand+1)=cham
        ngrand = ngrand + 1
    endif
    5 end do
!
!     --- SI AUCUN CHAMP DEMANDE NE PEUT ETRE TRAITE => ERREUR
    if (ngrand .eq. 0) then
        call utmess('F', 'ALGORITH17_28')
    endif
!
    vectot = '&&OP0181.VECTOT'
!
!     --- BOUCLE SUR LES CHAMPS A CALCULER
    do 10 i = 1, ngrand
!        --- CALCUL DES FFT DES CHAMPS
        call prefft(resin, method, symetr, nsens, grand(i),&
                    vectot, nbva, ier)
!
!     --- ECRITURE DES RESULTATS
!
        call ecresu(resin, vectot, nbva, grand(i), resou,&
                    ier)
10  end do
!
    call jedema()
end subroutine
