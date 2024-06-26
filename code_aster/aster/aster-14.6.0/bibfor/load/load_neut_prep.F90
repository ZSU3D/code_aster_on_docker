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

subroutine load_neut_prep(model, nb_in_maxi, nb_in_prep, lchin     , lpain,&
                          mate_, varc_curr_, temp_prev_, temp_iter_)
!
implicit none
!
#include "asterfort/assert.h"
#include "asterfort/exixfe.h"
#include "asterfort/xajcin.h"
#include "asterfort/mecara.h"
#include "asterfort/megeom.h"
!
! person_in_charge: mickael.abbas at edf.fr
!
    character(len=24), intent(in) :: model
    integer, intent(in) :: nb_in_maxi
    character(len=8), intent(inout) :: lpain(nb_in_maxi)
    character(len=19), intent(inout) :: lchin(nb_in_maxi)
    integer, intent(out) :: nb_in_prep
    character(len=24), optional, intent(in) :: mate_
    character(len=19), optional, intent(in) :: varc_curr_
    character(len=19), optional, intent(in) :: temp_prev_
    character(len=19), optional, intent(in) :: temp_iter_
!
! --------------------------------------------------------------------------------------------------
!
! Neumann loads computation - Thermic
!
! Preparing input fields for Neumann loads
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of model
! In  nb_in_maxi       : maximum number of input fields
! IO  lpain            : list of input parameters
! IO  lchin            : list of input fields
! Out nb_in_prep       : number of input fields before specific ones
! In  mate             : name of material characteristics (field)
! In  varc_curr        : command variable for current time
! In  temp_prev        : temperature at beginning of current time
! In  temp_iter        : temperature field at current Newton iteration
!
! --------------------------------------------------------------------------------------------------
!
    character(len=24) :: chgeom
!
! --------------------------------------------------------------------------------------------------
!
    nb_in_prep = 0
!
! - Geometry field
!
    call megeom(model, chgeom)
    nb_in_prep = 1
    lpain(nb_in_prep) = 'PGEOMER'
    lchin(nb_in_prep) = chgeom(1:19)   
!
! - Input fields
!
    if (present(temp_prev_)) then
        nb_in_prep = nb_in_prep + 1
        lpain(nb_in_prep) = 'PTEMPER'
        lchin(nb_in_prep) = temp_prev_(1:19)
    endif
    if (present(temp_iter_)) then
        nb_in_prep = nb_in_prep + 1
        lpain(nb_in_prep) = 'PTEMPEI'
        lchin(nb_in_prep) = temp_iter_(1:19)
    endif
    if (present(mate_)) then
        nb_in_prep = nb_in_prep + 1
        lpain(nb_in_prep) = 'PMATERC'
        lchin(nb_in_prep) = mate_(1:19)
    endif
    if (present(varc_curr_)) then
        nb_in_prep = nb_in_prep + 1
        lpain(nb_in_prep) = 'PVARCPR'
        lchin(nb_in_prep) = varc_curr_(1:19)
    endif
!
    ASSERT(nb_in_prep.le.nb_in_maxi)
!
end subroutine
