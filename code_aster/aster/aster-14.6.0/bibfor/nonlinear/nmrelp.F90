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
subroutine nmrelp(model          , nume_dof   , ds_material   , cara_elem, ds_system ,&
                  ds_constitutive, list_load  , list_func_acti, iter_newt, ds_measure,&
                  sdnume         , ds_algopara, ds_contact    , valinc   ,&
                  solalg         , veelem     , veasse        , ds_conv  , ldccvg,&
                  sddyna_)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterc/r8maem.h"
#include "asterfort/assert.h"
#include "asterfort/copisd.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/jeveuo.h"
#include "asterfort/nmaint.h"
#include "asterfort/nmcha0.h"
#include "asterfort/nmchai.h"
#include "asterfort/nmchex.h"
#include "asterfort/nmchso.h"
#include "asterfort/nmdebg.h"
#include "asterfort/nonlinRForceCompute.h"
#include "asterfort/nmfint.h"
#include "asterfort/nmmaji.h"
#include "asterfort/nmrebo.h"
#include "asterfort/nmrech.h"
#include "asterfort/nmrecz.h"
#include "asterfort/nmtime.h"
#include "asterfort/vlaxpy.h"
#include "asterfort/vtcreb.h"
#include "asterfort/vtzero.h"
#include "asterfort/zbinit.h"
#include "asterfort/nonlinSubStruCompute.h"
#include "blas/daxpy.h"
!
integer :: list_func_acti(*)
integer :: iter_newt, ldccvg
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
type(NL_DS_Contact), intent(in) :: ds_contact
type(NL_DS_Measure), intent(inout) :: ds_measure
character(len=19) :: list_load, sdnume
type(NL_DS_Material), intent(in) :: ds_material
character(len=24) :: model, nume_dof, cara_elem
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
type(NL_DS_System), intent(in) :: ds_system
character(len=19) :: veelem(*), veasse(*)
character(len=19) :: solalg(*), valinc(*)
type(NL_DS_Conv), intent(inout) :: ds_conv
character(len=19), intent(in), optional :: sddyna_
!
! --------------------------------------------------------------------------------------------------
!
! ROUTINE MECA_NON_LINE (ALGORITHME)
!
! RECHERCHE LINEAIRE DANS LA DIRECTION DE DESCENTE
!
! --------------------------------------------------------------------------------------------------
!
! In  model            : name of model
! In  cara_elem        : name of elementary characteristics (field)
! In  ds_material      : datastructure for material parameters
! In  list_load        : name of datastructure for list of loads
! In  nume_dof         : name of numbering object (NUME_DDL)
! In  ds_constitutive  : datastructure for constitutive laws management
! IO  ds_measure       : datastructure for measure and statistics management
! IN  FONACT : FONCTIONNALITES ACTIVEES
! IN  ITERAT : NUMERO D'ITERATION DE NEWTON
! IN  SDNUME : SD NUMEROTATION
! In  ds_contact       : datastructure for contact management
! In  ds_system        : datastructure for non-linear system management
! In  ds_algopara      : datastructure for algorithm parameters
! IN  VALINC : VARIABLE CHAPEAU POUR INCREMENTS VARIABLES
! IN  SOLALG : VARIABLE CHAPEAU POUR INCREMENTS SOLUTIONS
! IN  VEASSE : VARIABLE CHAPEAU POUR NOM DES VECT_ASSE
! IN  VEELEM : VARIABLE CHAPEAU POUR NOM DES VECT_ELEM
! OUT LDCCVG : CODE RETOUR DE L'INTEGRATION DU COMPORTEMENT
!                -1 : PAS D'INTEGRATION DU COMPORTEMENT
!                 0 : CAS DU FONCTIONNEMENT NORMAL
!                 1 : ECHEC DE L'INTEGRATION DE LA LDC
!                 3 : SIZZ PAS NUL POUR C_PLAN DEBORST
! IO  ds_conv          : datastructure for convergence management
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: zsolal = 17
    integer, parameter :: zvalin = 28
    integer :: itrlmx, iterho, neq, act, opt, ldcopt
    integer :: dimmem, nmax
    real(kind=8) :: rhomin, rhomax, rhoexm, rhoexp
    real(kind=8) :: rhom, rhoopt, rho
    real(kind=8) :: f0, fm, f, fopt, fcvg
    real(kind=8) :: parmul, relirl, sens
    real(kind=8) :: mem(2, 10)
    aster_logical :: stite, lnkry
    aster_logical :: lgrot, lendo
    character(len=19) :: cnfins(2), cndirs(2), k19bla
    character(len=19) :: depplu, sigplu, varplu, complu
    character(len=19) :: sigplt, varplt, depplt
    character(len=19) :: vefint, vediri
    character(len=19) :: cnfint, cndiri, cnfext, cnsstr
    character(len=19) :: depdet, ddepla, depdel, sddyna
    character(len=19) :: solalt(zsolal), valint(zvalin, 2)
    character(len=24) :: mate, varc_refe
    aster_logical :: echec
    integer :: ifm, niv
    real(kind=8), pointer :: vale(:) => null()
    type(NL_DS_System) :: ds_system2
!
! --------------------------------------------------------------------------------------------------
!
    call infdbg('MECANONLINE', ifm, niv)
    if (niv .ge. 2) then
        write (ifm,*) '<MECANONLINE> ... RECHERCHE LINEAIRE'
    endif
!
! --- FONCTIONNALITES ACTIVEES
!
    sddyna = ' '
    if (present(sddyna_)) then
        sddyna = sddyna_
    endif
    lgrot = isfonc(list_func_acti,'GD_ROTA')
    lendo = isfonc(list_func_acti,'ENDO_NO')
    lnkry = isfonc(list_func_acti,'NEWTON_KRYLOV')
!
! --- INITIALISATIONS
!
    mate      = ds_material%field_mate
    varc_refe = ds_material%varc_refe
    opt = 1
    parmul = 3.d0
    fopt = r8maem()
    k19bla = ' '
    ldccvg = -1
    call nmchai('VALINC', 'LONMAX', nmax)
    ASSERT(nmax.eq.zvalin)
    call nmchai('SOLALG', 'LONMAX', nmax)
    ASSERT(nmax.eq.zsolal)
!
! --- PARAMETRES RECHERCHE LINEAIRE
!
    itrlmx = ds_algopara%line_search%iter_maxi
    rhomin = ds_algopara%line_search%rho_mini
    rhomax = ds_algopara%line_search%rho_maxi
    rhoexm = -ds_algopara%line_search%rho_excl
    rhoexp = ds_algopara%line_search%rho_excl
    relirl = ds_algopara%line_search%resi_rela
    ASSERT(itrlmx.le.1000)
    dimmem = 10
!
! --- DECOMPACTION VARIABLES CHAPEAUX
!
    call nmchex(valinc, 'VALINC', 'DEPPLU', depplu)
    call nmchex(valinc, 'VALINC', 'SIGPLU', sigplu)
    call nmchex(valinc, 'VALINC', 'VARPLU', varplu)
    call nmchex(valinc, 'VALINC', 'COMPLU', complu)
    call nmchex(veasse, 'VEASSE', 'CNDIRI', cndiri)
    call nmchex(veasse, 'VEASSE', 'CNFEXT', cnfext)
    call nmchex(veasse, 'VEASSE', 'CNSSTR', cnsstr)
    call nmchex(veelem, 'VEELEM', 'CNDIRI', vediri)
    call nmchex(solalg, 'SOLALG', 'DDEPLA', ddepla)
    call nmchex(solalg, 'SOLALG', 'DEPDEL', depdel)
!
! - Copy dastructure for solving system
!
    ds_system2 = ds_system
    cnfint     = ds_system%cnfint
    vefint     = ds_system%vefint
!
! --- ACCES VARIABLES
!
    call jeveuo(ddepla(1:19)//'.VALE', 'E', vr=vale)
!
! --- PREPARATION DES ZONES TEMPORAIRES POUR ITERATION COURANTE
!
    cnfins(1) = cnfint
    cnfins(2) = '&&NMRECH.RESI'
    cndirs(1) = cndiri
    cndirs(2) = '&&NMRECH.DIRI'
    depdet = '&&CNPART.CHP1'
    depplt = '&&CNPART.CHP2'
    sigplt = '&&NMRECH.SIGP'
    varplt = '&&NMRECH.VARP'
    call vtzero(depdet)
    call vtzero(depplt)
    call copisd('CHAMP_GD', 'V', varplu, varplt)
    call copisd('CHAMP_GD', 'V', sigplu, sigplt)
    call vtcreb('&&NMRECH.RESI', 'V', 'R', nume_ddlz = nume_dof, nb_equa_outz = neq)
    call vtcreb('&&NMRECH.DIRI', 'V', 'R', nume_ddlz = nume_dof, nb_equa_outz = neq)
!
! --- CONSTRUCTION DES VARIABLES CHAPEAUX
!
    call nmcha0('VALINC', 'ALLINI', ' ', valint(1, 1))
    call nmchso(valinc, 'VALINC', '      ', k19bla, valint(1, 1))
    call nmchso(valint(1, 1), 'VALINC', 'DEPPLU', depplt, valint(1, 1))
    call nmcha0('VALINC', 'ALLINI', ' ', valint(1, 2))
    call nmchso(valinc, 'VALINC', '      ', k19bla, valint(1, 2))
    call nmchso(valint(1, 2), 'VALINC', 'DEPPLU', depplt, valint(1, 2))
    call nmchso(valint(1, 2), 'VALINC', 'SIGPLU', sigplt, valint(1, 2))
    call nmchso(valint(1, 2), 'VALINC', 'VARPLU', varplt, valint(1, 2))
    call nmchso(solalg, 'SOLALG', 'DEPDEL', depdet, solalt)
!
! --- CALCUL DE F(RHO=0)
!
    call nmrecz(nume_dof, ds_contact, list_func_acti, &
                cndiri, cnfint, cnfext, cnsstr, ddepla,&
                f0)
!
    if (niv .ge. 2) then
        write (ifm,*) '<MECANONLINE> ... FONCTIONNELLE INITIALE: ',f0
    endif
!
! --- VALEUR DE CONVERGENCE
!
    fcvg = abs(relirl * f0)
!
! --- INITIALISATION ET DIRECTION DE DESCENTE
!
    if (ds_algopara%line_search%method .eq. 'CORDE') then
        sens = 1.d0
        rhom = 0.d0
        fm = f0
        rhoopt = 1.d0
    else if (ds_algopara%line_search%method .eq.'MIXTE') then
        if (f0 .le. 0.d0) then
            sens = 1.d0
        else
            sens = -1.d0
        endif
        call zbinit(sens*f0, parmul, dimmem, mem)
        rhoopt = 1.d0
    else
        ASSERT(.false.)
    endif
!
! --- BOUCLE DE RECHERCHE LINEAIRE
!
    rho = sens
    act = 1
!
    do iterho = 0, itrlmx
!
! ----- CALCUL DE L'INCREMENT DE DEPLACEMENT TEMPORAIRE
!
        call nmmaji(nume_dof, lgrot, lendo, sdnume, rho,&
                    depdel, ddepla, depdet, 0)
        call nmmaji(nume_dof, lgrot, lendo, sdnume, rho,&
                    depplu, ddepla, depplt, 1)
        if (lnkry) then
            call vlaxpy(1.d0-rho, ddepla, depdet)
            call vlaxpy(1.d0-rho, ddepla, depplt)
        endif
! ----- Print
        if (niv .ge. 2) then
            write (ifm,*) '<MECANONLINE> ...... ITERATION <',iterho,'>'
            write (ifm,*) '<MECANONLINE> ...... RHO COURANT = ',rho
            write (ifm,*) '<MECANONLINE> ...... INCREMENT DEPL.'
            call nmdebg('VECT', depplt, 6)
            write (ifm,*) '<MECANONLINE> ...... INCREMENT DEPL. TOTAL'
            call nmdebg('VECT', depdet, 6)
        endif
! ----- Update internal forces
        ds_system2%cnfint = cnfins(act)
        ds_system2%vefint = vefint
        call nmfint(model         , cara_elem      ,&
                    ds_material   , ds_constitutive,&
                    list_func_acti, iter_newt      , ds_measure, ds_system2,&
                    valint(1, act), solalt         ,&
                    ldccvg        , sddyna)
        call nmaint(nume_dof, list_func_acti, sdnume, ds_system2)
! ----- Update force for Dirichlet boundary conditions (dualized) - BT.LAMBDA
        call nonlinRForceCompute(model   , ds_material, cara_elem, list_load,&
                                 nume_dof, ds_measure , depplt,&
                                 veelem  , cndiri_ = cndirs(act))
        if (niv .ge. 2) then
            write (ifm,*) '<MECANONLINE> ...... FORCES INTERNES'
            call nmdebg('VECT', cnfins(act), 6)
            write (ifm,*) '<MECANONLINE> ...... REACTIONS D''APPUI'
            call nmdebg('VECT', cndirs(act), 6)
        endif
!
! ----- ON A NECESSAIREMENT INTEGRE LA LOI DE COMPORTEMENT
!
        ASSERT(ldccvg.ne.-1)
!
! ----- ECHEC A L'INTEGRATION DE LA LOI DE COMPORTEMENT
!
        if (ldccvg .ne. 0) then
!
! ------- S'IL EXISTE DEJA UN RHO OPTIMAL, ON LE CONSERVE
!
            if (iterho .gt. 0) then
                goto 100
            else
                goto 999
            endif
        endif
!
! ----- CALCUL DE F(RHO)
!
        call nmrecz(nume_dof, ds_contact, list_func_acti, &
                    cndirs(act), cnfins(act), cnfext, cnsstr, ddepla, f)
!
        if (niv .ge. 2) then
            write (ifm,*) '<MECANONLINE> ... FONCTIONNELLE COURANTE: ',f
        endif
!
! ----- CALCUL DU RHO OPTIMAL
!
        if (ds_algopara%line_search%method .eq. 'CORDE') then
            call nmrech(fm, f, fopt, fcvg, rhomin,&
                        rhomax, rhoexm, rhoexp, rhom, rho,&
                        rhoopt, ldcopt, ldccvg, opt, act,&
                        stite)
!
        else if (ds_algopara%line_search%method .eq. 'MIXTE') then
            call nmrebo(f, mem, sens, rho, rhoopt,&
                        ldcopt, ldccvg, fopt, fcvg, opt,&
                        act, rhomin, rhomax, rhoexm, rhoexp,&
                        stite, echec)
            if (echec) then
                goto 100
            endif
        else
            ASSERT(.false.)
        endif
        if (stite) then
            goto 100
        endif
    end do
    iterho = itrlmx
!
! --- STOCKAGE DU RHO OPTIMAL ET DES CHAMPS CORRESPONDANTS
!
100 continue
!
! --- AJUSTEMENT DE LA DIRECTION DE DESCENTE
!
    call daxpy(neq, rhoopt-1.d0, vale, 1, vale, 1)
!
! --- RECUPERATION DES VARIABLES EN T+ SI NECESSAIRE
!
    if (opt .ne. 1) then
        call copisd('CHAMP_GD', 'V', sigplt, sigplu)
        call copisd('CHAMP_GD', 'V', varplt, varplu)
        call copisd('CHAMP_GD', 'V', cnfins(opt), cnfint)
        call copisd('CHAMP_GD', 'V', cndirs(opt), cndiri)
    endif
!
! --- INFORMATIONS SUR LA RECHERCHE LINEAIRE
!
    ldccvg = ldcopt
!
999 continue
!
! - Save results of line search
!
    ds_conv%line_sear_coef = rhoopt
    ds_conv%line_sear_iter = iterho
!
    call detrsd('CHAMP', '&&NMRECH.RESI')
    call detrsd('CHAMP', '&&NMRECH.DIRI')
!
end subroutine
