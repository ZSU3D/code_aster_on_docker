! --------------------------------------------------------------------
! Copyright (C) 1991 - 2020 - EDF R&D - www.code-aster.org
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

subroutine porigi(nomte, e, xnu, xl, klv)
!
!
! --------------------------------------------------------------------------------------------------
!
!     Calcul de la matrice de rigidité des éléments de poutre
!
!   IN
!       nomte : nom du type element 'MECA_POU_D_E'  'MECA_POU_D_T'
!       e       : module d'Young
!       xnu     : coefficient de poisson
!       xl      : longueur de l'élément
!       klv     : matrice de raideur
!
! --------------------------------------------------------------------------------------------------
!
    implicit none
    character(len=*) :: nomte
    real(kind=8) :: e, xnu, xl, klv(*)
!
! --------------------------------------------------------------------------------------------------
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/lonele.h"
#include "asterfort/poutre_modloc.h"
#include "asterfort/ptka01.h"
#include "asterfort/ptka02.h"
#include "asterfort/ptka21.h"
#include "asterfort/lteatt.h"
#include "asterfort/tecach.h"
#include "asterfort/utmess.h"
!
! --------------------------------------------------------------------------------------------------
!
    integer :: istruc, itype, lrcou, iret
    real(kind=8) :: a, a2, alfay, alfay2, alfaz, alfaz2
    real(kind=8) :: ey, ez, g
    real(kind=8) :: xfly, xflz, xiy, xiy2, xiz, xiz2
    real(kind=8) :: xjx, xjx2, xl_geom, xl0
    real(kind=8) :: xig
    aster_logical :: euler
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: nb_cara = 18
    real(kind=8) :: vale_cara(nb_cara)
    character(len=8) :: noms_cara(nb_cara)
    data noms_cara /'A1','IY1','IZ1','AY1','AZ1','EY1','EZ1','JX1','JG1',&
                    'A2','IY2','IZ2','AY2','AZ2','EY2','EZ2','JX2','TVAR'/
!
! --------------------------------------------------------------------------------------------------
!
    g = e/(2.0d0*(1.0d0+xnu))
    euler=lteatt('EULER','OUI')
!
!   recuperation des caracteristiques generales des sections
    xl_geom = lonele()
    call poutre_modloc('CAGNPO', noms_cara, nb_cara, lvaleur=vale_cara)
!
    a      = vale_cara(1)
    xiy    = vale_cara(2)
    xiz    = vale_cara(3)
    alfay  = vale_cara(4)
    alfaz  = vale_cara(5)
    xjx    = vale_cara(8)
    xig    = vale_cara(9)
    a2     = vale_cara(10)
    xiy2   = vale_cara(11)
    xiz2   = vale_cara(12)
    alfay2 = vale_cara(13)
    alfaz2 = vale_cara(14)
    xjx2   = vale_cara(17)
    ey = (vale_cara(6) +vale_cara(15))/2.d0
    ez = (vale_cara(7) +vale_cara(16))/2.d0
    itype = nint(vale_cara(18))
!
    if (xl .le. 0.0d0) then
        xl0 = xl_geom
    else
        xl0 = xl
    endif
!
    if (euler) then
!       poutre droite d'euler a 6 ddl
        istruc = 1
        alfay  = 0.0d0
        alfaz  = 0.0d0
        alfay2 = 0.0d0
        alfaz2 = 0.0d0
    else if (nomte.eq.'MECA_POU_D_T') then
        call tecach('ONN', 'PCAARPO', 'L', iret, iad=lrcou)
        if ( iret .eq. 0 ) then
            xfly = zr(lrcou)
            xflz = zr(lrcou+2)
!             if ( abs(xfly-1.0)+abs(xflz-1.0) .gt. 1.0E-8 ) then
!                 call utmess('F', 'ELEMENTS3_65', nr=2, valr=[xfly,xflz])
!             endif
            xiy  = xiy/xfly
            xiz  = xiz/xflz
            xiy2 = xiy2/xfly
            xiz2 = xiz2/xflz
        endif
        istruc = 1
    else if (nomte.eq.'MECA_POU_D_TG') then
        itype = 30
    else
        ASSERT(.false.)
    endif
!
!   calcul de la matrice de rigidite locale
    if (itype .eq. 0) then
!       poutre droite a section constante
        call ptka01(klv, e, a, xl0, xiy, xiz, xjx, g, alfay, alfaz, ey, ez, istruc)
!
    else if (itype.eq.1 .or. itype.eq.2) then
!       poutre droite a section variable (type 1 ou 2)
        call ptka02(itype, klv, e, a, a2, xl0, xiy, xiy2, xiz, xiz2,&
                    xjx, xjx2, g, alfay, alfay2, alfaz, alfaz2, ey, ez, istruc)
!
    else if (itype.eq.30) then
        call ptka21(klv, e, a, xl0, xiy, xiz, xjx, xig, g, alfay, alfaz, ey, ez)
    endif
!
end subroutine
