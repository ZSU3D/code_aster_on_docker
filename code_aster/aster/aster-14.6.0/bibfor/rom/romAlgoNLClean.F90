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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine romAlgoNLClean(ds_algorom)
!
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/romBaseClean.h"
!
type(ROM_DS_AlgoPara), intent(inout) :: ds_algorom
!
! --------------------------------------------------------------------------------------------------
!
! Model reduction - Solving non-linear problem
!
! Clean ROM algorithm datastructure
!
! --------------------------------------------------------------------------------------------------
!
! IO  ds_algorom       : datastructure for ROM parameters
!
! --------------------------------------------------------------------------------------------------
!
    AS_DEALLOCATE(vi = ds_algorom%v_equa_int)
    if (ds_algorom%l_hrom_corref) then
        AS_DEALLOCATE(vi = ds_algorom%v_equa_sub)
    endif
    call romBaseClean(ds_algorom%ds_empi)
!
end subroutine
