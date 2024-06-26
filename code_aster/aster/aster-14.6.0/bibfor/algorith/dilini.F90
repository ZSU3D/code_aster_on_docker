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

subroutine dilini(option, nomte, ivf, ivf2, idfde,&
                  idfde2, jgano, ndim, ipoids, ipoid2,&
                  icompo, npi, dimdef, nddls, nddlm,&
                  dimcon, typmod, dimuel, nno, nnom,&
                  nnos, regula, axi, interp)
! ======================================================================
! person_in_charge: romeo.fernandes at edf.fr
! aslint: disable=W1504
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/dimp0.h"
#include "asterfort/dimp1.h"
#include "asterfort/dimsl.h"
#include "asterfort/elref1.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/utmess.h"
#include "asterfort/lteatt.h"
!
    aster_logical :: axi
    integer :: ivf, ivf2, idfde, idfde2, jgano, ndim, ipoids, npi, nnom
    integer :: ipoid2, dimdef, dimuel, dimcon, nno, nnos, nddls, nddlm
    integer :: regula(6), icompo, nddlc
    character(len=2) :: interp
    character(len=8) :: typmod(2)
    character(len=16) :: option, nomte
! ======================================================================
! --- BUT : INITIALISATION DES GRANDEURS NECESSAIRES POUR LA GESTION ---
! ---       DU CALCUL AVEC REGULARISATION A PARTIR DU MODELE SECOND ----
! ---       GRADIENT A MICRO-DILATATION --------------------------------
! ======================================================================
! =====================================================================
! --- VARIABLES LOCALES ------------------------------------------------
! ======================================================================
    integer :: nno2, nnos2, npi2, nnoc
    character(len=8) :: elrefe, elrf1, elrf2
! ======================================================================
! --- INITIALISATION ---------------------------------------------------
! ======================================================================
    interp = '  '
    typmod(2) = '        '
    elrf1 = '        '
    elrf2 = '        '
    axi = .false.
    dimdef = 0
    dimcon = 0
! ======================================================================
! --- TYPE D'ELEMENT ---------------------------------------------------
! ======================================================================
    call elref1(elrefe)
    if (elrefe .eq. 'TR7') then
        interp = 'P0'
        elrf1 = 'TR6'
        elrf2 = 'TR3'
    else if (elrefe.eq.'QU9') then
        interp = 'P0'
        elrf1 = 'QU8'
        elrf2 = 'QU4'
    else if (elrefe.eq.'TR6') then
        interp = 'SL'
        elrf1 = 'TR6'
        elrf2 = 'TR3'
    else if (elrefe.eq.'QU8') then
        interp = 'SL'
        elrf1 = 'QU8'
        elrf2 = 'QU4'
    else if (elrefe.eq.'T10') then
        interp = 'P1'
        elrf1 = 'T10'
        elrf2 = 'TE4'
    else if (elrefe.eq.'P15') then
        interp = 'P1'
        elrf1 = 'P15'
        elrf2 = 'PE6'
    else if (elrefe.eq.'H20') then
        interp = 'P1'
        elrf1 = 'H20'
        elrf2 = 'HE8'
    else
        call utmess('F', 'DVP_4', sk=elrefe)
    endif
! ======================================================================
! --- FONCTIONS DE FORME P2 --------------------------------------------
! ======================================================================
    call elrefe_info(elrefe=elrf1, fami='RIGI', ndim=ndim, nno=nno, nnos=nnos,&
                     npg=npi, jpoids=ipoids, jvf=ivf, jdfde=idfde, jgano=jgano)
! ======================================================================
! --- FONCTIONS DE FORME P1 --------------------------------------------
! ======================================================================
    call elrefe_info(elrefe=elrf2, fami='RIGI', ndim=ndim, nno=nno2, nnos=nnos2,&
                     npg=npi2, jpoids=ipoid2, jvf=ivf2, jdfde=idfde2)
! ======================================================================
! --- RECUPERATION DU TYPE DE LA MODELISATION --------------------------
! ======================================================================
    if (lteatt('DIM_TOPO_MODELI','2')) then
        typmod(1) = 'D_PLAN'
    else if (lteatt('DIM_TOPO_MODELI','3')) then
        typmod(1) = '3D'
    else
        ASSERT(.false.)
    endif
! ======================================================================
    if (interp .eq. 'P0') then
        call dimp0(ndim, nno, nnos, dimdef, dimcon,&
                   nnom, nnoc, nddls, nddlm, nddlc,&
                   dimuel, regula)
    else if (interp.eq.'SL') then
        call dimsl(ndim, nno, nnos, dimdef, dimcon,&
                   nnom, nnoc, nddls, nddlm, nddlc,&
                   dimuel, regula)
    else if (interp.eq.'P1') then
        call dimp1(ndim, nno, nnos, dimdef, dimcon,&
                   nnom, nnoc, nddls, nddlm, nddlc,&
                   dimuel, regula)
    endif
! ======================================================================
end subroutine
