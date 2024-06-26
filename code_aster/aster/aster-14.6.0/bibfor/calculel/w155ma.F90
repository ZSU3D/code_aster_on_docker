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

subroutine w155ma(numa, nucou, nicou, nangl, nufib,&
                  motfac, jce2d, jce2l, jce2v, jce5d,&
                  jce5l, jce5v, ksp1, ksp2, c1,&
                  c2, iret)
! person_in_charge: jacques.pellet at edf.fr
! ======================================================================
    implicit none
#include "jeveux.h"
#include "asterc/r8pi.h"
#include "asterfort/assert.h"
#include "asterfort/cesexi.h"
#include "asterfort/utmess.h"
    integer :: numa, nucou, nangl, nufib, ksp1, ksp2
    integer :: jce2l, jce2d, jce2v, iret, jce5l, jce5d, jce5v
    real(kind=8) :: c1, c2
    character(len=3) :: nicou
    character(len=16) :: motfac
    integer :: iposi, nbcou, nbsec, isect, icou, npgh
    integer :: iad2, nbfib, iad2a
    real(kind=8) :: poi(2), omega, pi, angle, dxa

! ----------------------------------------------------------------------
! but : determiner ksp1, ksp2, c1 et c2
!       tels que pour la maille numa, le sous-point specifie par
!       (motfac,nucou,nicou,nangl,nufib)
!       soit = c1*ksp1+c2*ksp2
! out iret : / 0 -> ok : on peut utiliser c1,c2,ksp1 et ksp2
!            / 1 -> la maille numa n'est pas concernee

! remarque : l'interpolation n'est necessaire que pour les tuyaux.
!            dans les autres cas, ksp2=ksp1, c2=0., c1=1.
! ----------------------------------------------------------------------
    iret=0



!   -- calcul de iposi=1,2,3 : position dans la couche
!   ---------------------------------------------------
    if (motfac .eq. 'EXTR_COQUE' .or. motfac .eq. 'EXTR_TUYAU') then
        if (nicou .eq. 'INF') then
            iposi=1
        else if (nicou.eq.'MOY') then
            iposi=2
        else if (nicou.eq.'SUP') then
            iposi=3
        else
            ASSERT(.false.)
        endif
    endif




    if (motfac .eq. 'EXTR_COQUE') then
!   ---------------------------------
        ASSERT(nucou.ge.1)
!       -- extr_coque est utilise pour les coques :
!       -- cmp1 = coq_ncou
        call cesexi('C', jce2d, jce2l, numa, 1,&
                    1, 1, iad2a)

        if (iad2a .le. 0) then
            iret=1
            goto 9999
        else
            nbcou=zi(jce2v-1+iad2a)
            npgh=3
        endif
        if (nucou .gt. nbcou) then
            call utmess('F', 'CALCULEL2_14')
        endif

        ksp1=((nucou-1)*npgh)+iposi
        ksp2=ksp1
        c1=1.d0
        c2=0.d0


    else if (motfac.eq.'EXTR_PMF') then
!   ---------------------------------
        ASSERT(nufib.ge.1)
!       -- CMP4 = NBFIBR
        call cesexi('C', jce2d, jce2l, numa, 1,&
                    1, 4, iad2)
        if (iad2 .le. 0) then
            iret=1
            goto 9999
        endif
        nbfib=zi(jce2v-1+iad2)
        if (nufib .gt. nbfib) then
            call utmess('F', 'CALCULEL2_16')
        endif
        ksp1=nufib
        ksp2=ksp1
        c1=1.d0
        c2=0.d0


    else if (motfac.eq.'EXTR_TUYAU') then
!   ---------------------------------
        ASSERT(nucou.ge.1)
!       -- CMP2 = TUY_NCOU
        call cesexi('C', jce2d, jce2l, numa, 1,&
                    1, 2, iad2)
        if (iad2 .le. 0) then
            iret=1
            goto 9999
        endif
        nbcou=zi(jce2v-1+iad2)
        if (nucou .gt. nbcou) then
            call utmess('F', 'CALCULEL2_14')
        endif
!       -- CMP3 = TUY_NSEC
        call cesexi('C', jce2d, jce2l, numa, 1,&
                    1, 3, iad2)
        ASSERT(iad2.gt.0)
        nbsec=zi(jce2v-1+iad2)
        if (nucou .gt. nbcou) then
            call utmess('F', 'CALCULEL2_14')
        endif
        icou=2*(nucou-1)+iposi

!       -- CMP1 = ANGZZK
        call cesexi('C', jce5d, jce5l, numa, 1,&
                    1, 1, iad2)
        omega=zr(jce5v-1+iad2)


!       -- morceau de code extrait de te0597 :
        pi=r8pi()
        angle=nangl*pi/180.d0
!       CALL CARCOU(...,OMEGA)
        dxa=pi/nbsec
        isect=int((omega+angle)/dxa)+1
        poi(1)=1.d0-((omega+angle)/dxa+1.d0-isect)
        poi(2)=1.d0-(isect-(omega+angle)/dxa)
        if (isect .gt. (2*nbsec)) isect=isect-2*nbsec
        if (isect .lt. 1) isect=isect+2*nbsec
        if (isect .le. 0 .or. isect .gt. (2*nbsec)) then
            call utmess('F', 'ELEMENTS4_51')
        endif
!       -- fin morceau te0597

        ksp1=(2*nbsec+1)*(icou-1)+isect
        ksp2=ksp1+1
        c1=poi(1)
        c2=poi(2)


    else
        ASSERT(.false.)
    endif

9999  continue


end subroutine
