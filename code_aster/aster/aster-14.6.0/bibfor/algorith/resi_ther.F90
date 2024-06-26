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
!
subroutine resi_ther(model    , mate     , time     , compor    , temp_prev,&
                     temp_iter, hydr_prev, hydr_curr, dry_prev  , dry_curr ,&
                     varc_curr, resu_elem, vect_elem, base)
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/calcul.h"
#include "asterfort/corich.h"
#include "asterfort/gcnco2.h"
#include "asterfort/megeom.h"
#include "asterfort/reajre.h"
#include "asterfort/inical.h"
!
character(len=24), intent(in) :: model
character(len=24), intent(in) :: time
character(len=24), intent(in) :: mate
character(len=24), intent(in) :: temp_prev
character(len=24), intent(in) :: temp_iter
character(len=24), intent(in) :: hydr_prev   
character(len=24), intent(in) :: hydr_curr
character(len=24), intent(in) :: dry_prev   
character(len=24), intent(in) :: dry_curr
character(len=24), intent(in) :: compor
character(len=19), intent(in) :: varc_curr
character(len=19), intent(in) :: resu_elem
character(len=24), intent(in) :: vect_elem
character(len=1), intent(in) :: base
!
! --------------------------------------------------------------------------------------------------
!
! Thermic
! 
! Residuals from non-linear laws 
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of the model
! In  mate             : name of material characteristics (field)
! In  time             : time (<CARTE>)
! In  temp_prev        : previous temperature
! In  temp_iter        : temperature field at current Newton iteration
! In  hydr_prev        : previous hydratation
! In  hydr_curr        : current hydratation
! In  dry_prev         : previous drying
! In  dry_curr         : current drying
! In  compor           : name of comportment definition (field)
! In  varc_curr        : command variable for current time
! In  resu_elem        : name of resu_elem
! In  vect_elem        : name of vect_elem result
! In  base             : JEVEUX base for object
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: nbin  = 10
    integer, parameter :: nbout = 2
    character(len=8) :: lpain(nbin), lpaout(nbout)
    character(len=19) :: lchin(nbin), lchout(nbout)
!
    character(len=1) :: stop_calc
    character(len=16) :: option
    character(len=24) :: ligrel_model
    character(len=24) :: chgeom
    integer :: ibid
!
! --------------------------------------------------------------------------------------------------
!
    stop_calc    = 'S'
    option       = 'RESI_RIGI_MASS'
    ligrel_model = model(1:8)//'.MODELE'
!
! - Init fields
!
    call inical(nbin  , lpain, lchin, nbout, lpaout,&
                lchout)    
!
! - Geometry field
!
    call megeom(model, chgeom)
!
! - Input fields
!
    lpain(1)  = 'PGEOMER'
    lchin(1)  = chgeom(1:19)
    lpain(2)  = 'PMATERC'
    lchin(2)  = mate(1:19)
    lpain(3)  = 'PTEMPSR'
    lchin(3)  = time(1:19)
    lpain(4)  = 'PTEMPEI'
    lchin(4)  = temp_iter(1:19)
    lpain(5)  = 'PHYDRPM'
    lchin(5)  = hydr_prev(1:19)
    lpain(6)  = 'PCOMPOR'
    lchin(6)  = compor(1:19)
    lpain(7)  = 'PTEMPER'
    lchin(7)  = temp_prev(1:19)
    lpain(8)  = 'PTMPCHI'
    lchin(8)  = dry_prev(1:19)
    lpain(9)  = 'PTMPCHF'
    lchin(9)  = dry_curr(1:19)
    lpain(10) = 'PVARCPR'
    lchin(10) = varc_curr(1:19)
!
! - Output fields
!
    lpaout(1) = 'PRESIDU'
    lchout(1) = resu_elem(1:19)
    lpaout(2) = 'PHYDRPP'
    lchout(2) = hydr_curr(1:19)
!
    call corich('E', lchout(1), -1, ibid)
!
! - Number of fields
!
    call calcul(stop_calc, option, ligrel_model, nbin  , lchin,&
                lpain    , nbout , lchout      , lpaout, base ,&
                'OUI')
!
! - Add RESU_ELEM in vect_elem
!
    call reajre(vect_elem, lchout(1), base)
!
end subroutine
