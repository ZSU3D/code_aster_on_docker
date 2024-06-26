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

subroutine te0359(option, nomte)
!
! person_in_charge: jerome.laverne at edf.fr
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/eiangl.h"
#include "asterfort/eiinit.h"
#include "asterfort/elref2.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/jevech.h"
#include "asterfort/lteatt.h"
#include "asterfort/pipeei.h"
#include "asterfort/tecach.h"
#include "asterfort/utmess.h"
!
    character(len=16) :: option, nomte
!
! ----------------------------------------------------------------------
!    - FONCTION REALISEE:  PILOTAGE PRED_ELAS
!                          POUR LES ELEMENTS D'INTERFACE
!    - ARGUMENTS:
!        DONNEES:      OPTION       -->  OPTION DE CALCUL
!                      NOMTE        -->  NOM DU TYPE ELEMENT
! ----------------------------------------------------------------------
    character(len=8) :: lielrf(10)
    aster_logical :: axi
    integer :: nno1, nno2, npg, lgpg, ndim, iret, ntrou, iu(3, 18), im(3, 9)
    integer :: it(18)
    integer :: iw, ivf1, idf1, igeom, imate, ivf2, idf2, nnos, jgn, jtab(7)
    integer :: ivarim, icopil, ictau, iddlm, iddld, iddl0, iddl1, icompo, icamas
    real(kind=8) :: ang(24)
!
!
!
!
! - FONCTIONS DE FORME
!
    call elref2(nomte, 2, lielrf, ntrou)
    call elrefe_info(elrefe=lielrf(1), fami='RIGI', ndim=ndim, nno=nno1, nnos=nnos,&
                     npg=npg, jpoids=iw, jvf=ivf1, jdfde=idf1, jgano=jgn)
    call elrefe_info(elrefe=lielrf(2), fami='RIGI', ndim=ndim, nno=nno2, nnos=nnos,&
                     npg=npg, jpoids=iw, jvf=ivf2, jdfde=idf2, jgano=jgn)
    ndim = ndim + 1
    axi = lteatt('AXIS','OUI')
!
! - DECALAGE D'INDICE POUR LES ELEMENTS D'INTERFACE
    call eiinit(nomte, iu, im, it)
!
! --- ORIENTATION DE L'ELEMENT D'INTERFACE : REPERE LOCAL
!     RECUPERATION DES ANGLES NAUTIQUES DEFINIS PAR AFFE_CARA_ELEM
!
    call jevech('PCAMASS', 'L', icamas)
    if (zr(icamas) .eq. -1.d0) then
        call utmess('F', 'ELEMENTS5_47')
    endif
!
!     DEFINITION DES ANGLES NAUTIQUES AUX NOEUDS SOMMETS : ANG
!
    call eiangl(ndim, nno2, zr(icamas+1), ang)
!
! - PARAMETRES
!
    call jevech('PGEOMER', 'L', igeom)
    call jevech('PMATERC', 'L', imate)
    call jevech('PCOMPOR', 'L', icompo)
    call jevech('PDEPLMR', 'L', iddlm)
    call jevech('PDDEPLR', 'L', iddld)
    call jevech('PDEPL0R', 'L', iddl0)
    call jevech('PDEPL1R', 'L', iddl1)
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PCDTAU', 'L', ictau)
    call jevech('PCOPILO', 'E', icopil)
!
!    NOMBRE DE VARIABLES INTERNES
    call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                itab=jtab)
    lgpg = max(jtab(6),1)*jtab(7)
!
!
! - PILOTAGE PRED_ELAS
!
    call pipeei(ndim, axi, nno1, nno2, npg,&
                zr(iw), zr(ivf1), zr(ivf2), zr(idf2), zr(igeom),&
                ang, zi(imate), zk16(icompo), lgpg, zr(iddlm),&
                zr(iddld), zr(iddl0), zr(iddl1), zr(ictau), zr(ivarim),&
                iu, im, zr(icopil))
!
end subroutine
