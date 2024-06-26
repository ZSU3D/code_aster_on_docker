! --------------------------------------------------------------------
! Copyright (C) 1991 - 2018 - EDF R&D - www.code-aster.org
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
subroutine rrc_comp_dual(ds_para)
!
use Rom_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/infniv.h"
#include "asterfort/utmess.h"
#include "asterfort/as_allocate.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/rsexch.h"
#include "asterfort/jeveuo.h"
#include "blas/dgemm.h"
#include "blas/dgesv.h"
#include "asterfort/rsnoch.h"
#include "asterfort/copisd.h"
#include "asterfort/romBaseCreateMatrix.h"
#include "asterfort/romResultSetZero.h"
#include "asterfort/romEvalGappyPOD.h"
!
type(ROM_DS_ParaRRC), intent(in) :: ds_para
!
! --------------------------------------------------------------------------------------------------
!
! REST_REDUIT_COMPLET - Compute
!
! Compute dual field
!
! --------------------------------------------------------------------------------------------------
!
! In  ds_para          : datastructure for parameters
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ifm, niv
    integer :: nb_mode, nb_equa, nb_equa_ridi, nb_store
    integer :: iret, i_mode, i_equa, i_store, nume_store, i_ord, nume_equa
    character(len=8) :: result_rom, result_dom
    real(kind=8), pointer :: v_dual(:) => null()
    real(kind=8), pointer :: v_dual_rom(:) => null()
    real(kind=8), pointer :: v_sigm_dom(:) => null()
    real(kind=8), pointer :: v_sigm_rid(:) => null()
    real(kind=8), pointer :: v_sigm_rom(:) => null()
    real(kind=8), pointer :: v_cohr(:) => null()
    character(len=24) :: field_save, sigm_rid
    real(kind=8), pointer :: v_field_save(:) => null()
    type(ROM_DS_Field) :: ds_mode
!
! --------------------------------------------------------------------------------------------------
!
    call infniv(ifm, niv)
    if (niv .ge. 2) then
        call utmess('I', 'ROM6_22')
    endif
!
! - Get parameters
!
    nb_store     = ds_para%nb_store
    ds_mode      = ds_para%ds_empi_dual%ds_mode
    nb_mode      = ds_para%ds_empi_dual%nb_mode
    nb_equa      = ds_mode%nb_equa
    result_rom   = ds_para%result_rom
    result_dom   = ds_para%result_dom
    nb_equa_ridi = ds_para%nb_equa_ridi
!
! - Create [PHI] matrix for dual base
!
    call romBaseCreateMatrix(ds_para%ds_empi_dual, v_dual)
!
! - Reduce [PHI] matrix on RID
!
    AS_ALLOCATE(vr = v_dual_rom, size = nb_equa_ridi*nb_mode)
    do i_mode = 1, nb_mode
        do i_equa = 1, nb_equa
            if (ds_para%v_equa_ridd(i_equa) .ne. 0) then
                v_dual_rom(ds_para%v_equa_ridd(i_equa)+nb_equa_ridi*(i_mode-1)) = &
                  v_dual(i_equa+nb_equa*(i_mode-1))
            endif 
        end do
    end do
!
! - Gappy POD 
!
    call romEvalGappyPOD(ds_para, result_rom, nb_store, v_dual_rom,&
                         v_cohr , 1)
!
! - Initial state
!
    nume_store = 0
    call romResultSetZero(result_dom, nume_store, ds_mode)
!
! - Compute new fields
!
    AS_ALLOCATE(vr = v_sigm_dom, size = nb_equa*(nb_store-1))
    call dgemm('N', 'N', nb_equa, nb_store-1, nb_mode, 1.d0, &
               v_dual, nb_equa, v_cohr, nb_mode, 0.d0, v_sigm_dom, nb_equa)
!
! - Compute new field
!
    do i_store = 1, nb_store-1
        nume_store = i_store
! ----- Get field to save
        call rsexch(' ', result_dom, ds_mode%field_name,&
                    nume_store, field_save, iret)
        ASSERT(iret .eq. 100)
        call copisd('CHAMP_GD', 'G', ds_mode%field_refe, field_save)
        call jeveuo(field_save(1:19)//'.VALE', 'E', vr = v_field_save)
! ----- Get field on RID
        call rsexch(' ', result_rom, ds_mode%field_name,&
                    nume_store, sigm_rid, iret)
        ASSERT(iret .eq. 0)
        call jeveuo(sigm_rid(1:19)//'.VALE', 'L', vr = v_sigm_rid)
! ----- Truncate the field
        AS_ALLOCATE(vr = v_sigm_rom, size = nb_equa_ridi)
        do i_ord = 1, ds_para%nb_equa_ridd
            if (ds_para%v_equa_ridi(i_ord) .ne. 0) then
                v_sigm_rom(ds_para%v_equa_ridi(i_ord)) = v_sigm_rid(i_ord)
            endif
        enddo
! ----- Set field
        do i_equa = 1, nb_equa
            nume_equa = ds_para%v_equa_ridd(i_equa)
            if (nume_equa .eq. 0) then
                v_field_save(i_equa) = v_sigm_dom(i_equa+nb_equa*(nume_store-1))
            else
                v_field_save(i_equa) = v_sigm_rom(nume_equa)
            endif
        enddo
        call rsnoch(result_dom, ds_mode%field_name, nume_store)
        AS_DEALLOCATE(vr = v_sigm_rom)
    enddo
!
! - Clean
!
    AS_DEALLOCATE(vr  = v_dual)
    AS_DEALLOCATE(vr  = v_dual_rom)
    AS_DEALLOCATE(vr  = v_cohr)
    AS_DEALLOCATE(vr  = v_sigm_dom)
!
end subroutine
