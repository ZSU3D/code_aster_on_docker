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

subroutine load_neum_matr(idx_load    , idx_matr  , load_name , load_nume, load_type,&
                          ligrel_model, nb_in_maxi, nb_in_prep, lpain    , lchin    ,&
                          matr_elem   )
!
    implicit none
!
#include "asterfort/assert.h"
#include "asterfort/calcul.h"
#include "asterfort/codent.h"
#include "asterfort/reajre.h"
#include "asterfort/jeveuo.h"
#include "asterfort/load_neum_spec.h"
!
! person_in_charge: mickael.abbas at edf.fr
!
    character(len=8), intent(in) :: load_name
    integer, intent(in) :: idx_load
    integer, intent(inout) :: idx_matr
    integer, intent(in) :: load_nume
    character(len=4), intent(in) :: load_type
    character(len=19), intent(in) :: ligrel_model
    integer, intent(in) :: nb_in_maxi
    integer, intent(in) :: nb_in_prep
    character(len=*), intent(inout) :: lpain(nb_in_maxi)
    character(len=*), intent(inout) :: lchin(nb_in_maxi)
    character(len=19), intent(in) :: matr_elem
!
! --------------------------------------------------------------------------------------------------
!
! Compute Neumann loads
! 
! Elementary (on one load) - Matrix for undead loads
!
! --------------------------------------------------------------------------------------------------
!
! In  idx_load       : index of current load
! In  idx_matr       : index of current matrix
! In  load_name      : name of current load
! In  load_nume      : identification of load type
! In  load_type      : load type to compute - 'Dead', 'Pilo' or 'Suiv'
! In  ligrel_model   : LIGREL on model
! In  nb_in_maxi     : maximum number of input fields
! In  nb_in_prep     : number of input fields before specific ones
! IO  lpain          : list of input parameters
! IO  lchin          : list of input fields
! In  matr_elem      : name of matr_elem result
!
! --------------------------------------------------------------------------------------------------
!
    integer :: nb_type_neum
    parameter (nb_type_neum=18)
!
    integer :: i_type_neum, nb_in_add
    character(len=16) :: load_option
    character(len=24) :: load_ligrel  
    integer :: nbout, nbin
    character(len=8) :: lpaout
    character(len=19) :: lchout
    character(len=8) :: matr_type
    character(len=24), pointer :: p_matr_elem_relr(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    nbout  = 1
    lchout = '&&MECGME.00000000'
!
    do i_type_neum = 1, nb_type_neum
!
! ----- Get information about load
!
        call load_neum_spec(load_name   , load_nume  , load_type  , ligrel_model, i_type_neum,&
                            nb_type_neum, nb_in_maxi , nb_in_prep , lchin       , lpain      ,&
                            nb_in_add   , load_ligrel, load_option, matr_type)
!
        if (load_option .ne. 'No_Load') then
!
! --------- Number of fields
!
            nbin  = nb_in_prep+nb_in_add
            nbout = 1
!
! --------- New RESU_ELEM
!
            if (idx_matr.ge.0) then
                lpaout         = matr_type
                lchout (10:10) = 'G'
                idx_matr       = idx_matr + 1
                call codent(idx_load, 'D0', lchout(7:8))
                call codent(idx_matr, 'D0', lchout(12:14))
            endif
!
! --------- Old RESU_ELEM
!
            if (idx_matr.lt.0) then
                lpaout = matr_type
                call jeveuo(matr_elem//'.RELR', 'L', vk24 = p_matr_elem_relr)
                lchout = p_matr_elem_relr(abs(idx_matr))(1:19)
            endif
!
! --------- Computation
!
            call calcul('S'  , load_option, ligrel_model, nbin  , lchin,&
                        lpain, nbout      , lchout      , lpaout, 'V'  ,&
                        'OUI')
!
! --------- Copying output field
!
            if (idx_matr.ge.0) then
                call reajre(matr_elem, lchout, 'V')
            endif
        endif
    end do

end subroutine
