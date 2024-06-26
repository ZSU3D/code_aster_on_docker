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
! aslint: disable=W1504
!
subroutine nmpost(modele , mesh    , numedd, numfix     , carele  ,&
                  ds_constitutive, numins  , ds_material, ds_system,&
                  ds_contact, ds_algopara, fonact  ,&
                  ds_measure, sddisc     , &
                  sd_obsv, sderro  , sddyna, ds_posttimestep, valinc  ,&
                  solalg , meelem  , measse, veasse  ,&
                  ds_energy, sdcriq  , eta   , lischa)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/cfmxpo.h"
#include "asterfort/isfonc.h"
#include "asterfort/lobs.h"
#include "asterfort/diinst.h"
#include "asterfort/nmener.h"
#include "asterfort/nmetca.h"
#include "asterfort/nmleeb.h"
#include "asterfort/nmobse.h"
#include "asterfort/nmspec.h"
#include "asterfort/nmtime.h"
#include "asterfort/nmrinc.h"
#include "asterfort/nmrest_ecro.h"
#include "asterfort/nmchex.h"
#include "asterfort/nmobsw.h"
!
integer :: numins
character(len=8), intent(in) :: mesh
real(kind=8) :: eta
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
type(NL_DS_Material), intent(in) :: ds_material
character(len=19) :: meelem(*)
type(NL_DS_Contact), intent(inout) :: ds_contact
type(NL_DS_Energy), intent(inout) :: ds_energy
character(len=19) :: lischa
character(len=19) :: sddisc, sddyna
type(NL_DS_PostTimeStep), intent(inout) :: ds_posttimestep
character(len=19), intent(in) :: sd_obsv
character(len=24) :: modele, numedd, numfix
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(NL_DS_System), intent(in) :: ds_system
character(len=19) :: measse(*), veasse(*)
character(len=19) :: solalg(*), valinc(*)
type(NL_DS_Measure), intent(inout) :: ds_measure
character(len=24) :: sderro, sdcriq
character(len=24) :: carele
integer :: fonact(*)
!
! --------------------------------------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (ALGORITHME)
!
! CALCULS DE POST-TRAITEMENT
!
! --------------------------------------------------------------------------------------------------
!
! IN  MODELE : MODELE
! IN  NUMEDD : NUME_DDL
! IN  NUMFIX : NUME_DDL (FIXE AU COURS DU CALCUL)
! In  ds_material      : datastructure for material parameters
! IN  CARELE : CARACTERISTIQUES DES ELEMENTS DE STRUCTURE
! In  ds_constitutive  : datastructure for constitutive laws management
! In  ds_system        : datastructure for non-linear system management
! IO  ds_contact       : datastructure for contact management
! IO  ds_measure       : datastructure for measure and statistics management
! IN  SDDYNA : SD POUR LA DYNAMIQUE
! IO  ds_energy        : datastructure for energy management
! In  ds_algopara      : datastructure for algorithm parameters
! IN  NUMINS : NUMERO D'INSTANT
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SOLALG : VARIABLE CHAPEAU POUR INCREMENTS SOLUTIONS
! IO  ds_posttimestep  : datastructure for post-treatment at each time step
! IN  SDCRIQ : SD CRITERE QUALITE
!
! --------------------------------------------------------------------------------------------------
!
    aster_logical :: l_mode_vibr, l_crit_stab, lerrt, lcont, lener, l_post_incr, l_obsv
    character(len=4) :: etfixe
    real(kind=8) :: time
    character(len=19) :: varc_curr, disp_curr, strx_curr
!
! --------------------------------------------------------------------------------------------------
!
    lcont       = isfonc(fonact,'CONTACT')
    lerrt       = isfonc(fonact,'ERRE_TEMPS_THM')
    l_mode_vibr = isfonc(fonact,'MODE_VIBR')
    l_crit_stab = isfonc(fonact,'CRIT_STAB')
    lener       = isfonc(fonact,'ENERGIE')
    l_post_incr = isfonc(fonact,'POST_INCR')    
!
! - Extract variables
!    
    call nmchex(valinc, 'VALINC', 'DEPPLU', disp_curr)
    call nmchex(valinc, 'VALINC', 'STRPLU', strx_curr)
    call nmchex(valinc, 'VALINC', 'COMPLU', varc_curr)
!
! - Observation ?
!
    l_obsv = ASTER_FALSE
    time   = diinst(sddisc, numins)
    call lobs(sd_obsv, numins, time, l_obsv)
!
! - State of time loop
!
    call nmleeb(sderro, 'FIXE', etfixe)
!
! - Post-treatment ?
!
    if (etfixe .eq. 'CONV') then
! ----- Launch timer for post-treatment
        call nmtime(ds_measure, 'Init'  , 'Post')
        call nmtime(ds_measure, 'Launch', 'Post')
! ----- CALCUL EVENTUEL DE L'INDICATEUR D'ERREUR TEMPORELLE THM
        if (lerrt) then
            call nmetca(modele, mesh  , ds_material, sddisc, sdcriq,&
                        numins, valinc)
        endif
!
! ----- Post-treatment for contact
!
        if (lcont) then
            call cfmxpo(mesh      , modele, ds_contact, numins, sddisc,&
                        ds_measure, solalg, valinc    )
        endif
!
! ----- Spectral analysis (MODE_VIBR/CRIT_STAB)
!
        if (l_mode_vibr .or. l_crit_stab) then
            call nmspec(modele         , ds_material, carele    ,lischa      , fonact,&
                        numedd         , numfix     , ds_system ,&
                        ds_constitutive, &
                        sddisc         , numins    ,&
                        sddyna         , sderro    , ds_algopara,&
                        ds_measure     ,&
                        valinc         , solalg    ,&
                        meelem         , measse    ,&
                        ds_posttimestep)
        endif
!
! ----- CALCUL DES ENERGIES
!
        if (lener) then
            call nmener(valinc         , veasse    , measse, sddyna     , eta        ,&
                        ds_energy      , fonact    , numedd, numfix     ,&
                        meelem         , numins    , modele, ds_material, carele     ,&
                        ds_constitutive, ds_measure, sddisc, solalg     ,&
                        ds_contact     , ds_system)
        endif
!
! ----- Post-treatment for behavior laws.
!
        if (l_post_incr) then
            call nmrest_ecro(modele, ds_material%field_mate, ds_constitutive, valinc)
        endif
!
! ----- Make observation
!        
        if (l_obsv) then
            call nmobse(mesh     , sd_obsv  , time,&
                        carele, modele   , ds_material, ds_constitutive, disp_curr,&
                        strx_curr , varc_curr)
        endif
!
! ----- End of timer for post-treatment
!
        call nmtime(ds_measure, 'Stop', 'Post')
        call nmrinc(ds_measure, 'Post')
    endif
!
end subroutine
