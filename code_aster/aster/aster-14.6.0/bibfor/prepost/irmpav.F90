! --------------------------------------------------------------------
! Copyright (C) 1991 - 2019 - EDF R&D - www.code-aster.org
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

subroutine irmpav(nomcon, ifichi, linopa, numdt, numit,&
                  dt)
    use as_med_module, only: as_med_open
    implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/as_mficom.h"
#include "asterfort/as_mficlo.h"
#include "asterfort/as_mprrvw.h"
#include "asterfort/assert.h"
#include "asterfort/codent.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/rsadpa.h"
#include "asterfort/ulisog.h"
#include "asterfort/utmess.h"
!
    character(len=19) :: linopa
    character(len=*) :: nomcon
    integer :: ifichi, numdt, numit
    real(kind=8) :: dt
! person_in_charge: nicolas.sellenet at edf.fr
!
!-----------------------------------------------------------------------
!     CREATION D'UN PARAMETRE DANS UN FICHIER MED
!
! IN  NOMCON : K8  : NOM DU CONCEPT A IMPRIMER
! IN  IFICHI : IS  : UNITE LOGIQUE D'ECRITURE
! IN  NOPARA : K16 : NOM D'UN PARAMATRE A AJOUTER
! IN  NUMDT  : I   : NUMERO D'ORDRE
! IN  NUMIT  : I   : NUMERO D'ITERATION
! IN  DT     : R   : VALEUR DU PAS DE TEMPS
! IN  VAL    : R   : VALEUR DU PARAMETRE
!     ------------------------------------------------------------------
!
!     ------------------------------------------------------------------
    med_idt :: idfimd
    integer :: edleaj, codret, hdfok, medok, jlnopa
    integer :: nbpara, inopar, iaux
    character(len=1) :: saux01
    character(len=8) :: saux08
    character(len=16) :: nopara
    character(len=64) :: saux64
    character(len=200) :: nofimd
    character(len=255) :: kfic
!
    aster_logical :: ficexi
!     ------------------------------------------------------------------
    call jemarq()
!
    call ulisog(ifichi, kfic, saux01)
    if (kfic(1:1) .eq. ' ') then
        call codent(ifichi, 'G', saux08)
        nofimd = 'fort.'//saux08
    else
        nofimd = kfic(1:200)
    endif
    inquire(file=nofimd,exist=ficexi)
    if (ficexi) then
        call as_mficom(nofimd, hdfok, medok, codret)
        if ( medok.eq.0.or.hdfok.eq.0.or.codret.ne.0 ) then
            edleaj = 3
            call as_med_open(idfimd, nofimd, edleaj, codret)
        else
            edleaj = 1
            call as_med_open(idfimd, nofimd, edleaj, codret)
        endif
    else
        edleaj = 3
        call as_med_open(idfimd, nofimd, edleaj, codret)
    endif
    if (codret .ne. 0) then
        saux08='mfiope'
        call utmess('F', 'DVP_97', sk=saux08, si=codret)
    endif
!
    call jeveuo(linopa, 'L', jlnopa)
    call jelira(linopa, 'LONMAX', nbpara)
    do inopar = 0, nbpara-1
        nopara = zk16(jlnopa+inopar)
        call rsadpa(nomcon, 'L', 1, nopara, numdt,&
                    0, sjv=iaux, styp=saux08, istop=1)
!
        saux64 = nomcon//nopara
        call as_mprrvw(idfimd, saux64, numdt, numit, dt,&
                       zr(iaux), codret)
        if (codret .ne. 0) then
            saux08='mprcre'
            call utmess('F', 'DVP_97', sk=saux08, si=codret)
        endif
    enddo
!
    call as_mficlo(idfimd, codret)
    if (codret .ne. 0) then
        saux08='mficlo'
        call utmess('F', 'DVP_97', sk=saux08, si=codret)
    endif
!
    call jedema()
end subroutine
