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
subroutine dbr_para_info_rb(ds_para_rb)
!
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/infniv.h"
#include "asterfort/utmess.h"
#include "asterfort/romSolveInfo.h"
#include "asterfort/romMultiParaInfo.h"
!
type(ROM_DS_ParaDBR_RB), intent(in) :: ds_para_rb
!
! --------------------------------------------------------------------------------------------------
!
! DEFI_BASE_REDUITE - Initializations
!
! Informations about DEFI_BASE_REDUITE parameters
!
! --------------------------------------------------------------------------------------------------
!
! In  ds_para_rb       : datastructure for parameters (RB)
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ifm, niv
    integer :: nb_mode_maxi
    real(kind=8) :: tole_greedy
!
! --------------------------------------------------------------------------------------------------
!
    call infniv(ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'ROM7_21')
    endif
!
! - Get parameters in datastructure - General for POD
!
    nb_mode_maxi = ds_para_rb%nb_mode_maxi
    tole_greedy  = ds_para_rb%tole_greedy
!
! - Print - General for RB
!
    if (niv .ge. 2) then
        call utmess('I', 'ROM5_17', si = nb_mode_maxi)
        call utmess('I', 'ROM5_21', sr = tole_greedy)
        call utmess('I', 'ROM3_39')
        call romMultiParaInfo(ds_para_rb%multipara)
        call utmess('I', 'ROM3_37')
        call romSolveInfo(ds_para_rb%algoGreedy%solveDOM)
        call utmess('I', 'ROM3_38')
        call romSolveInfo(ds_para_rb%algoGreedy%solveROM)
    endif
!
end subroutine
