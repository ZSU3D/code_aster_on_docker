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
!
subroutine carc_init(mesh, carcri, nb_cmp)
!
implicit none

#include "asterfort/alcart.h"
#include "asterfort/assert.h"
#include "asterfort/jelira.h"
#include "asterfort/jenonu.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/Behaviour_type.h"
!
character(len=8) , intent(in) :: mesh
character(len=19) , intent(in) :: carcri
integer, intent(out) :: nb_cmp
!
! --------------------------------------------------------------------------------------------------
!
! Preparation of comportment (mechanics)
!
! Initialization of CARCRI <CARTE>
!
! --------------------------------------------------------------------------------------------------
!
! In  mesh     : namle of mesh
! In  compor   : name of <CARTE> CARCRI
! Out nb_cmp   : number of components in <CARTE>
!
! --------------------------------------------------------------------------------------------------
!
    integer :: nume_gd
    integer :: nb_cmp_max, icmp
    character(len=8) :: name_gd
    real(kind=8)    , pointer :: p_carcri_valv(:) => null()
    character(len=8), pointer :: p_cata_nomcmp(:) => null()
    character(len=8), pointer :: p_carcri_ncmp(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    nb_cmp  = 0
    name_gd = 'CARCRI'
!
! - Read catalog
!
    call jenonu(jexnom('&CATA.GD.NOMGD', name_gd), nume_gd)
    call jeveuo(jexnum('&CATA.GD.NOMCMP', nume_gd), 'L', vk8 = p_cata_nomcmp)
    call jelira(jexnum('&CATA.GD.NOMCMP', nume_gd), 'LONMAX', nb_cmp_max)
    ASSERT(nb_cmp_max .le. CARCRI_SIZE)
!
! - Allocate <CARTE>
!
    call alcart('V', carcri, mesh, name_gd)
!
! - Acces to <CARTE>
!
    call jeveuo(carcri(1:19)//'.NCMP', 'E', vk8 = p_carcri_ncmp)
    call jeveuo(carcri(1:19)//'.VALV', 'E', vr  = p_carcri_valv)
!
! - Init <CARTE>
!
    do icmp = 1, nb_cmp_max
        p_carcri_ncmp(icmp) = p_cata_nomcmp(icmp)
        p_carcri_valv(icmp) = 0.d0
    enddo
!
! - Default values
!
    p_carcri_valv(1) = 10
    p_carcri_valv(2) = 0
    p_carcri_valv(3) = 1.d-6
    p_carcri_valv(4) = 1.d0
!
    nb_cmp = nb_cmp_max

end subroutine
