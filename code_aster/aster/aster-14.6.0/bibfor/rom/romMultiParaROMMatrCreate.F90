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
subroutine romMultiParaROMMatrCreate(ds_empi  , ds_multipara, i_coef,&
                                     syst_matr)
!
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/infniv.h"
#include "asterfort/jeveuo.h"
#include "asterfort/rsexch.h"
#include "asterfort/utmess.h"
#include "blas/zdotc.h"
!
type(ROM_DS_Empi), intent(in) :: ds_empi
type(ROM_DS_MultiPara), intent(inout) :: ds_multipara
integer, intent(in) :: i_coef
character(len=19), intent(in) :: syst_matr
!
! --------------------------------------------------------------------------------------------------
!
! Model reduction
!
! Create matrix for multiparametric problems (reduced problem)
!
! --------------------------------------------------------------------------------------------------
!
! In  ds_empi          : datastructure for empiric modes
! IO  ds_multipara     : datastructure for multiparametric problems
! In  i_coef           : index of coefficient
! In  syst_matr        : name of matrix
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ifm, niv
    integer :: nb_matr, nb_mode, nb_equa, nb_mode_maxi
    integer :: i_mode, i_matr, j_mode
    aster_logical :: l_coef_cplx, l_coef_real
    real(kind=8) :: coef_r
    complex(kind=8) :: coef_c, coef_cplx
    complex(kind=8), pointer :: vc_syst_matr(:) => null()
    complex(kind=8), pointer :: vc_matr_red(:) => null()
    real(kind=8), pointer :: vr_syst_matr(:) => null()
    real(kind=8), pointer :: vr_matr_red(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call infniv(ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'ROM5_67')
    endif
!
! - Initializations
!
    nb_mode        = ds_empi%nb_mode
    nb_mode_maxi   = ds_empi%nb_mode_maxi
    nb_equa        = ds_empi%ds_mode%nb_equa
    nb_matr        = ds_multipara%nb_matr
!
    if(ds_multipara%syst_type .eq.'R') then 
       call jeveuo(syst_matr, 'E', vr = vr_syst_matr)
       vr_syst_matr(:) = 0.d0
    else if(ds_multipara%syst_type .eq.'C') then 
       call jeveuo(syst_matr, 'E', vc = vc_syst_matr)
       vc_syst_matr(:) = dcmplx(0.d0,0.d0)  
    else 
       ASSERT(ASTER_FALSE)
    end if 
!
! - Compute matrix
! 
    if (ds_multipara%syst_type .eq.'R') then 
        do i_matr = 1, nb_matr
           l_coef_cplx = ds_multipara%matr_coef(i_matr)%l_cplx
           l_coef_real = ds_multipara%matr_coef(i_matr)%l_real
           if (l_coef_cplx) then
               ASSERT(.false.)
           else
               coef_r    = ds_multipara%matr_coef(i_matr)%coef_real(i_coef)
           endif
           call jeveuo(ds_multipara%matr_redu(i_matr), 'L', vr = vr_matr_red)
           do i_mode = 1, nb_mode
              do j_mode = 1, nb_mode 
                 vr_syst_matr(nb_mode*(i_mode-1)+j_mode)=vr_syst_matr(nb_mode*(i_mode-1)+j_mode)+&
                                          vr_matr_red(nb_mode_maxi*(i_mode-1)+j_mode)*coef_r 
              end do 
            end do
         end do
    else if (ds_multipara%syst_type .eq.'C') then 
        do i_matr = 1, nb_matr
           l_coef_cplx = ds_multipara%matr_coef(i_matr)%l_cplx
           l_coef_real = ds_multipara%matr_coef(i_matr)%l_real
           if (l_coef_cplx) then
               coef_c    = ds_multipara%matr_coef(i_matr)%coef_cplx(i_coef)
               coef_cplx = coef_c
           else
               coef_r    = ds_multipara%matr_coef(i_matr)%coef_real(i_coef)
               coef_cplx = dcmplx(coef_r)
           endif
           call jeveuo(ds_multipara%matr_redu(i_matr), 'L', vc = vc_matr_red)
           do i_mode = 1, nb_mode
              do j_mode = 1, nb_mode 
                 vc_syst_matr(nb_mode*(i_mode-1)+j_mode)=vc_syst_matr(nb_mode*(i_mode-1)+j_mode)+&
                                          vc_matr_red(nb_mode_maxi*(i_mode-1)+j_mode)*coef_cplx 
              end do 
            end do
         end do
    else 
       ASSERT(ASTER_FALSE)
    end if
!
end subroutine
