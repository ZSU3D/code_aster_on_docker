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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine ntdata(list_load, solver, matcst   , coecst  , result,&
                  model    , mate  , cara_elem, ds_inout, theta )
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterc/getres.h"
#include "asterfort/cresol.h"
#include "asterfort/ntdoth.h"
#include "asterfort/ntdomt.h"
#include "asterfort/nonlinDSInOutRead.h"
!
character(len=19), intent(inout) :: list_load
character(len=19), intent(in) :: solver
aster_logical, intent(out) :: matcst
aster_logical, intent(out) :: coecst
character(len=8), intent(out) :: result
character(len=24), intent(out) :: model
character(len=24), intent(out) :: mate
character(len=24), intent(out) :: cara_elem
type(NL_DS_InOut), intent(inout) :: ds_inout
real(kind=8), intent(out) :: theta
!
! --------------------------------------------------------------------------------------------------
!
! Thermics - Initializations
!
! Read parameters (linear)
!
! --------------------------------------------------------------------------------------------------
!
! Out matcst           : .true. if constant material parameters
! Out coecst           : .true. if constant rigidity matrix
! Out result           : name of datastructure for results
! Out model            : name of model
! Out mate             : name of material characteristics (field)
! Out cara_elem        : name of datastructure for elementary parameters (CARTE)
! IO  ds_inout         : datastructure for input/output management
! Out theta            : value for PARM_THETA
!
! --------------------------------------------------------------------------------------------------
!
    character(len=16) :: k16bid
    character(len=8) :: k8bid
!
! --------------------------------------------------------------------------------------------------
!

!
! - Get datastructure for results
!
    call getres(result, k16bid, k8bid)
!
! - Read parameters
!
    call ntdoth(model, mate, cara_elem, list_load,&
                matcst_ = matcst, coecst_ = coecst )
!
! - Get parameters for linear solver
!
    call cresol(solver)
!
! - Get algorithm parameters and criteria
!
    call ntdomt(theta)
!
! - Read parameters for input/output management
!
    call nonlinDSInOutRead('THER', result, ds_inout)
!
end subroutine
