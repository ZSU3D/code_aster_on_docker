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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine romAlgoNLInit(phenom        , model, mesh, nume_dof, result, ds_algorom,&
                         l_line_search_)
!
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/infniv.h"
#include "asterfort/romCreateEquationFromNode.h"
#include "asterfort/romAlgoNLCheck.h"
#include "asterfort/romAlgoNLTableCreate.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
!
character(len=4), intent(in) :: phenom
character(len=24), intent(in) :: model
character(len=8), intent(in) :: mesh
character(len=24), intent(in) :: nume_dof
character(len=8), intent(in) :: result
type(ROM_DS_AlgoPara), intent(inout) :: ds_algorom
aster_logical, intent(in), optional :: l_line_search_
!
! --------------------------------------------------------------------------------------------------
!
! Model reduction - Solving non-linear problem
!
! Init ROM algorithm datastructure
!
! --------------------------------------------------------------------------------------------------
!
! In  phenom           : phenomenon (MECA/THER)
! In  model            : name of model
! In  mesh             : name of mesh
! In  nume_dof         : name of numbering (NUME_DDL)
! In  result           : name of datastructure for results
! IO  ds_algorom       : datastructure for ROM parameters
! In  l_line_search    : .true. if line search
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ifm, niv
    aster_logical :: l_hrom, l_hrom_corref
    integer :: nb_mode
    character(len=24) :: gamma
    real(kind=8), pointer :: v_gamma(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call infniv(ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'ROM5_37')
    endif
!
! - Get parameters
!
    l_hrom        = ds_algorom%l_hrom
    l_hrom_corref = ds_algorom%l_hrom_corref
    nb_mode       = ds_algorom%ds_empi%nb_mode
!
! - Check ROM algorithm datastructure
!
    call romAlgoNLCheck(phenom, model, mesh, ds_algorom, l_line_search_)
!
! - Prepare the list of equations at interface
!
    if (l_hrom) then
        call romCreateEquationFromNode(ds_algorom%ds_empi%ds_mode, ds_algorom%v_equa_int, nume_dof,&
                                       grnode_ = ds_algorom%grnode_int)
    endif
!
! - Prepare the list of equation of internal interface
!
    if (l_hrom_corref) then
        call romCreateEquationFromNode(ds_algorom%ds_empi%ds_mode, ds_algorom%v_equa_sub, nume_dof,&
                                       grnode_ = ds_algorom%grnode_sub)
    endif
!
! - Initializations for EF correction
!
    ds_algorom%phase = 'HROM'
!
! - Create object for reduced coordinates
!
    gamma = '&&GAMMA'
    call wkvect(gamma, 'V V R', nb_mode, vr = v_gamma)
    ds_algorom%gamma = gamma
!
! - Create table for the reduced coordinates
!
    call romAlgoNLTableCreate(result, ds_algorom)
!
end subroutine
