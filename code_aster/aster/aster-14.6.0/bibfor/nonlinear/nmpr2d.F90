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

subroutine nmpr2d(mode, laxi, nno, npg, poidsg,&
                  vff, dff, geom, p, vect,&
                  matc)
!
    implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/r8inir.h"
#include "asterfort/subac1.h"
#include "asterfort/subacv.h"
#include "asterfort/sumetr.h"
#include "asterfort/utmess.h"
    aster_logical :: laxi
    integer :: mode, nno, npg
    real(kind=8) :: poidsg(npg), vff(nno, npg), dff(nno, npg)
    real(kind=8) :: geom(2, nno), p(2, npg)
    real(kind=8) :: vect(2, nno), matc(2, nno, 2, nno)
!
!.......................................................................
!     MODE=1 : CALCUL DU SECOND MEMBRE POUR DES EFFORTS DE PRESSION
!     MODE=2 : CALCUL DE LA RIGIDITE DUE A LA PRESSION (SI SUIVEUSE)
!.......................................................................
! IN  MODE    SELECTION SECOND MEMBRE (1) OU BIEN RIGIDITE (2)
! IN  LAXI    TRUE EN AXISYMETRIQUE
! IN  NNO     NOMBRE DE NOEUDS
! IN  NPG     NOMBRE DE POINTS D'INTEGRATION
! IN  POIDSG  POIDS DES POINTS D'INTEGRATION
! IN  VFF     VALEUR DES FONCTIONS DE FORME AUX POINTS D'INTEGRATION
! IN  DFF     DERIVEE DES FONCTIONS DE FORME AUX POINTS D'INTEGRATION
! IN  GEOM    COORDONNEES DES NOEUDS
! IN  P       PRESSION AUX POINTS D'INTEGRATION (ET CISAILLEMENT)
! OUT VECT    VECTEUR SECOND MEMBRE                      (MODE = 1)
! OUT MATC    MATRICE CARREE NON SYMETRIQUE DE RIGIDITE  (MODE = 2)
!.......................................................................
    integer :: kpg, n, i, m, j
    real(kind=8) :: cova(3, 3), metr(2, 2), jac, cnva(3, 2)
    real(kind=8) :: t1, t2, t, acv(2, 2), r
!
!
!    INITIALISATION
    if (mode .eq. 1) call r8inir(nno*2, 0.d0, vect, 1)
    if (mode .eq. 2) call r8inir(nno*nno*4, 0.d0, matc, 1)
!
!
!    INTEGRATION AUX POINTS DE GAUSS
!
    do 100 kpg = 1, npg
!
!      ON NE SAIT PAS TRAITER LE CISAILLEMENT SUIVEUR
        if (p(2,kpg) .ne. 0.d0) then
            call utmess('F', 'ALGORITH8_24')
        endif
!
!      VERIFICATION QUE L'ELEMENT N'EST PAS CONFONDU AVEC L'AXE
        if (laxi) then
            r = 0.d0
            do 2 n = 1, nno
                r = r + vff(n,kpg)*geom(1,n)
  2         continue
            if (r .eq. 0.d0) then
                if (p(1,kpg) .ne. 0.d0) then
                    call utmess('F', 'ALGORITH8_25')
                endif
                goto 100
            endif
        endif
!
!
!      CALCUL DES ELEMENTS GEOMETRIQUES DIFFERENTIELS
        call subac1(laxi, nno, vff(1, kpg), dff(1, kpg), geom,&
                    cova)
        call sumetr(cova, metr, jac)
!
!      CALCUL DU SECOND MEMBRE
        if (mode .eq. 1) then
            do 10 n = 1, nno
                do 11 i = 1, 2
                    vect(i,n) = vect(i,n)- poidsg(kpg)*jac*p(1,kpg) * cova(i,3)*vff(n,kpg)
 11             continue
 10         continue
!
!
!      CALCUL DE LA RIGIDITE
        else if (mode.eq.2) then
            call subacv(cova, metr, jac, cnva, acv)
!
!        MATRICE NON SYMETRIQUE DV.MATC.DU
            do 20 m = 1, nno
                do 21 j = 1, 2
                    do 30 n = 1, nno
                        do 31 i = 1, 2
                            t1 = dff(m,kpg)*cnva(j,1) * vff(n,kpg)* cova(i,3)
                            t2 = dff(m,kpg)*cova(j,3) * vff(n,kpg)* cnva(i,1)
                            t = poidsg(kpg)*p(1,kpg) * jac * (t1 - t2)
                            matc(i,n,j,m) = matc(i,n,j,m) + t
 31                     continue
 30                 continue
 21             continue
 20         continue
!
!       TERME COMPLEMENTAIRE EN AXISYMETRIQUE
            if (laxi) then
                do 40 n = 1, nno
                    do 50 m = 1, nno
                        do 51 j = 1, 2
                            t1 = vff(n,kpg)*vff(m,kpg) * cnva(3,2)* cova(j,3)
                            t = poidsg(kpg)*p(1,kpg) * jac * t1
                            matc(1,n,j,m) = matc(1,n,j,m) + t
 51                     continue
 50                 continue
 40             continue
            endif
!
        else
            ASSERT(.false.)
        endif
!
100 end do
!
end subroutine
