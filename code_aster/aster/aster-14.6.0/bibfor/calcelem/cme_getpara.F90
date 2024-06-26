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
!
subroutine cme_getpara(option      ,&
                       model       , cara_elem, mate, compor_mult,&
                       v_list_load8, nb_load  ,&
                       rigi_meca   , mass_meca,&
                       time_curr   , time_incr, nh       ,&
                       sigm        , strx     , disp)
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/chpver.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvid.h"
#include "asterfort/getvis.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/rcmfmc.h"
#include "asterfort/utmess.h"
#include "asterfort/get_load8.h"
!
character(len=16), intent(out) :: option
character(len=8), intent(out) :: model
character(len=8), intent(out) :: cara_elem
character(len=24), intent(out) :: mate
character(len=24), intent(out) :: compor_mult
character(len=8), pointer :: v_list_load8(:)
integer, intent(out) :: nb_load
character(len=19), intent(out) :: rigi_meca
character(len=19), intent(out) :: mass_meca
real(kind=8), intent(out) :: time_curr
real(kind=8), intent(out) :: time_incr
integer, intent(out) :: nh
character(len=8), intent(out) :: sigm
character(len=8), intent(out) :: strx
character(len=8), intent(out) :: disp
!
! --------------------------------------------------------------------------------------------------
!
! CALC_MATR_ELEM
!
! Get parameters
!
! --------------------------------------------------------------------------------------------------
!
! Out option           : option to compute
! Out model            : name of the model
! Out cara_elem        : name of elementary characteristics (field)
! Out mate             : name of material characteristics (field)
! Out compor_mult      : multi-behaviours for multifibers beams (field)
! Out v_list_load8     : pointer to list of loads (K8)
! Out nb_load          : number of loads
! Out rigi_meca        : option for mechanic rigidity (useful for damping)
! Out mass_meca        : option for mechanic mass (useful for damping)
! Out time_curr        : current time
! Out time_incr        : time step
! Out nh               : Fourier mode
! Out sigm             : stress
! Out strx             : fibers information
! Out disp             : displacements
!
! --------------------------------------------------------------------------------------------------
!
    integer :: nocc, ier
    character(len=8) :: chmate, answer
    aster_logical :: l_ther
!
! --------------------------------------------------------------------------------------------------
!
    option       = ' '
    rigi_meca    = ' '
    mass_meca    = ' '
    time_curr    = 0.d0
    time_incr    = 0.d0
    nh           = 0
    model        = ' '
    cara_elem    = ' '
    mate         = ' '
    chmate       = ' '
    compor_mult  = ' '
    v_list_load8 => null()
    nb_load      = 0
    sigm         = ' '
    strx         = ' '
    disp         = ' '
!
! - Get parameters
!
    call getvtx(' ', 'OPTION'   , scal=option, nbret=nocc)
    ASSERT(nocc.eq.1)
    call getvid(' ', 'RIGI_MECA', scal=rigi_meca, nbret=nocc)
    if (nocc .eq. 0) then
        rigi_meca = ' '
    endif
    call getvid(' ', 'MASS_MECA', scal=mass_meca, nbret=nocc)
    if (nocc .eq. 0) then
        mass_meca = ' '
    endif
    call getvr8(' ', 'INST', scal=time_curr, nbret=nocc)
    if (nocc .eq. 0) then
        time_curr = 0.d0
    endif
    call getvr8(' ', 'INCR_INST', scal=time_incr, nbret=nocc)
    if (nocc .eq. 0) then
        time_incr = 0.d0
    endif
    call getvis(' ', 'MODE_FOURIER', scal=nh, nbret=nocc)
    if (nocc .eq. 0) then
        nh = 0
    endif
    call getvid(' ', 'MODELE', scal=model, nbret=nocc)
    ASSERT(nocc.eq.1)
    call getvid(' ', 'CARA_ELEM', scal=cara_elem, nbret=nocc)
    call dismoi('EXI_RDM', model, 'MODELE', repk=answer)
    if ((nocc.eq.0) .and. (answer.eq.'OUI')) then
        call utmess('A', 'MECHANICS1_39')
        cara_elem = ' '
    endif

    call getvid(' ', 'CHAM_MATER', scal=chmate, nbret=nocc)
    
    if (nocc .eq. 0) then 
        chmate = ' '
        if (option.eq.'RIGI_GEOM')  then
            ! necessaire seulement pour CABLE 
            call dismoi('SI_CABLE', model, 'MODELE', repk=answer)
            if (answer .eq. 'OUI') then
                call utmess('A', 'MECHANICS1_40')
            endif
        elseif ((option .ne. 'RIGI_ACOU') .and. (option.ne.'RIGI_GEOM') ) then
            ! mater pas besoin pour RIGI_ACOU, 
            ! mater peu besoin pour DIS_/2D_DIS_ pour d'autres options
            call dismoi('BESOIN_MATER', model, 'MODELE', repk=answer)
            if (answer .eq. 'OUI') then
                call utmess('A', 'MECHANICS1_40')
            endif            
        endif
    endif


    l_ther = ASTER_FALSE
    if (option .eq. 'MASS_THER' .or. option.eq. 'RIGI_THER') then
        l_ther = ASTER_TRUE
    endif

    if (chmate .ne. ' ') then
        call rcmfmc(chmate, mate, l_ther_ = l_ther)
    else
        mate = ' '
    endif
    call get_load8(model, v_list_load8, nb_load)
! - For multifibers
    compor_mult = mate(1:8)//'.COMPOR'
!
    if (option.eq.'RIGI_GEOM') then
        call getvid(' ', 'SIEF_ELGA', scal=sigm, nbret=nocc)
        if (nocc .ne. 0) then
            call chpver('F', sigm, 'ELGA', 'SIEF_R', ier)
        endif
        call getvid(' ', 'STRX_ELGA', scal=strx, nbret=nocc)
        if (nocc .ne. 0) then
            call chpver('F', strx, 'ELGA', 'STRX_R', ier)
        endif
        call getvid(' ', 'DEPL', scal=disp, nbret=nocc)
        if (nocc .ne. 0) then
            call chpver('F', disp, 'NOEU', 'DEPL_R', ier)
        endif
    endif
!
end subroutine
