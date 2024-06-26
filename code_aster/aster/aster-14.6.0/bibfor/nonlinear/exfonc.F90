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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine exfonc(list_func_acti, ds_algopara, solver, ds_contact, sddyna,&
                  mate, model)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/cfdisl.h"
#include "asterfort/exi_thms.h"
#include "asterfort/getvtx.h"
#include "asterfort/isfonc.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/ndynlo.h"
#include "asterfort/utmess.h"
#include "asterfort/dismoi.h"
!
integer, intent(in) :: list_func_acti(*)
character(len=19), intent(in) :: solver
character(len=19), intent(in) :: sddyna
type(NL_DS_Contact), intent(in) :: ds_contact
character(len=24), intent(in) :: mate
character(len=24), intent(in) :: model
type(NL_DS_AlgoPara), intent(in) :: ds_algopara
!
! --------------------------------------------------------------------------------------------------
!
! MECA_NON_LINE - Initializations
!
! Check compatibility of some functionnalities
!
! --------------------------------------------------------------------------------------------------
!
! In  list_func_acti   : list of active functionnalities
! In  ds_algopara      : datastructure for algorithm parameters
! In  solver           : datastructure for solver parameters
! In  ds_contact       : datastructure for contact management
! In  sddyna           : dynamic parameters datastructure
! In  mate             : name of material characteristics (field)
!
! --------------------------------------------------------------------------------------------------
!
    integer :: reac_incr, reac_iter
    aster_logical :: l_cont, lallv, l_cont_cont, l_cont_disc, lpena, leltc, l_cont_lac, l_iden_rela
    aster_logical :: l_pilo, l_line_search, lmacr, l_unil, l_diri_undead, l_cont_xfem
    aster_logical :: l_vibr_mode, l_buckling, lexpl, lxfem, lmodim, l_mult_front
    aster_logical :: l_cont_gcp, lpetsc, lamg, limpex, l_matr_distr, lgcpc
    aster_logical :: londe, l_dyna, l_grot_gdep, l_newt_krylov, l_mumps, l_rom
    aster_logical :: l_energy, lproj, lmatdi, lldsp, l_comp_rela, lammo, lthms, limpl
    aster_logical :: l_unil_pena, l_cont_acti
    character(len=24) :: typilo, metres, char24
    character(len=16) :: reli_meth, matrix_pred, partit
    character(len=3) :: mfdet
    character(len=24), pointer :: slvk(:) => null()
    integer, pointer :: slvi(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
! - Active functionnalites
!
    lxfem           = isfonc(list_func_acti,'XFEM')
    l_cont_cont     = isfonc(list_func_acti,'CONT_CONTINU')
    l_cont_disc     = isfonc(list_func_acti,'CONT_DISCRET')
    l_cont_xfem     = isfonc(list_func_acti,'CONT_XFEM')
    l_cont          = isfonc(list_func_acti,'CONTACT')
    l_cont_lac      = isfonc(list_func_acti,'CONT_LAC')
    l_unil          = isfonc(list_func_acti,'LIAISON_UNILATER')
    l_pilo          = isfonc(list_func_acti,'PILOTAGE')
    l_line_search   = isfonc(list_func_acti,'RECH_LINE')
    lmacr           = isfonc(list_func_acti,'MACR_ELEM_STAT')
    l_vibr_mode     = isfonc(list_func_acti,'MODE_VIBR')
    l_buckling      = isfonc(list_func_acti,'CRIT_STAB')
    londe           = ndynlo(sddyna,'ONDE_PLANE')
    l_dyna          = ndynlo(sddyna,'DYNAMIQUE')
    limpl           = ndynlo(sddyna,'IMPLICITE')
    lexpl           = isfonc(list_func_acti,'EXPLICITE')
    l_grot_gdep     = isfonc(list_func_acti,'GD_ROTA')
    lammo           = ndynlo(sddyna,'AMOR_MODAL')
    limpex          = isfonc(list_func_acti,'IMPLEX')
    l_newt_krylov   = isfonc(list_func_acti,'NEWTON_KRYLOV')
    l_rom           = isfonc(list_func_acti,'ROM')
    l_energy        = isfonc(list_func_acti,'ENERGIE')
    lproj           = isfonc(list_func_acti,'PROJ_MODAL')
    lmatdi          = isfonc(list_func_acti,'MATR_DISTRIBUEE')
    leltc           = isfonc(list_func_acti,'ELT_CONTACT')
    l_comp_rela     = isfonc(list_func_acti,'RESI_COMP')
    lgcpc           = isfonc(list_func_acti,'GCPC')
    lpetsc          = isfonc(list_func_acti,'PETSC')
    lldsp           = isfonc(list_func_acti,'LDLT_SP')
    l_mumps         = isfonc(list_func_acti,'MUMPS')
    l_mult_front    = isfonc(list_func_acti,'MULT_FRONT')
    l_diri_undead   = isfonc(list_func_acti,'DIRI_UNDEAD')
    l_matr_distr    = isfonc(list_func_acti,'MATR_DISTRIBUEE')
!
! - Get algorithm parameters
!
    reac_iter        = ds_algopara%reac_iter
    reac_incr        = ds_algopara%reac_incr
    matrix_pred      = ds_algopara%matrix_pred
    reli_meth        = ds_algopara%line_search%method
!
! - Get solver parameters
!
    call jeveuo(solver//'.SLVK', 'E', vk24=slvk)
    call jeveuo(solver//'.SLVI', 'E', vi  =slvi)
    metres = slvk(1)
    lamg  = ((slvk(2).eq.'ML') .or. (slvk(2).eq.'BOOMER'))
!
! - Contact (DISCRETE)
!
    if (l_cont_disc) then
        lmodim      = cfdisl(ds_contact%sdcont_defi,'MODI_MATR_GLOB')
        lallv       = cfdisl(ds_contact%sdcont_defi,'ALL_VERIF')
        lpena       = cfdisl(ds_contact%sdcont_defi,'CONT_PENA')
        l_cont_gcp  = cfdisl(ds_contact%sdcont_defi,'CONT_GCP')
        l_cont_acti = cfdisl(ds_contact%sdcont_defi,'CONT_ACTI')
        if (l_pilo) then
            call utmess('F', 'MECANONLINE_43')
        endif
        if (l_line_search .and. (.not.lallv)) then
            call utmess('A', 'MECANONLINE3_89')
        endif
        if (lgcpc .or. lpetsc) then
            if (.not.(lallv.or.lpena.or.l_cont_gcp)) then
                call utmess('F', 'MECANONLINE3_90', sk=metres)
            endif
            if (l_cont_gcp .and. .not.lldsp) then
                call utmess('F', 'MECANONLINE3_88')
            endif
        endif
        if (reac_incr .eq. 0) then
            if (lmodim) then
                call utmess('F', 'CONTACT_88')
            endif
        endif
        if ((l_vibr_mode.or.l_buckling) .and. lmodim) then
            call utmess('F', 'MECANONLINE5_14')
        endif
    endif
!
! - Contact (CONTINUE)
!
    if (l_cont_cont) then
        if (l_pilo .and. (.not.lxfem)) then
            call utmess('F', 'MECANONLINE3_92')
        endif
        if (l_line_search) then
            call utmess('F', 'MECANONLINE3_91')
        endif
        if (lamg) then
            call utmess('F', 'MECANONLINE3_97', sk=slvk(2))
        endif
        if (lpetsc .and. lmatdi) then
            call utmess('F', 'MECANONLINE3_98')
        endif
        if (lammo) then
            call utmess('F', 'MECANONLINE3_93')
        endif
    endif
!
! - Contact (XFEM)
!
    if (l_cont_xfem) then
        l_iden_rela = ds_contact%l_iden_rela
        if (l_iden_rela .and. l_mult_front) then
            call utmess('F', 'MECANONLINE3_99')
        endif
        if (reac_iter .ne. 1) then
            call utmess('F', 'MECANONLINE5_72')
        endif
    endif
!
! - Contact (LAC)
!
    if (l_cont_lac) then
        l_iden_rela = ds_contact%l_iden_rela
        if (l_iden_rela .and. l_mult_front) then
            call utmess('F', 'MECANONLINE3_99')
        elseif (l_matr_distr) then
            call utmess('F', 'CONTACT2_19')
        elseif ((lpetsc .or. lgcpc).and. .not. lldsp) then
            call utmess('F', 'MECANONLINE3_87')
        endif
    endif
!
! - Contact: excluion CONTACT+DISTRIBUTION/MODEL AUTRE QUE CENTRALISE (SDNV105C en // issue25915)
!
    if (l_cont) then
        if (limpl) then
            call dismoi('PARTITION', model(1:8)//'.MODELE', 'LIGREL', repk=partit)
            if ((partit .ne. ' ')) then
                call utmess('F', 'CONTACT3_46')
            endif
        endif
    endif
!
! - Unilateral link
!
    if (l_unil) then
        l_unil_pena = cfdisl(ds_contact%sdcont_defi, 'UNIL_PENA')
        if (l_unil_pena) then
           lmodim = .true.
           if (reac_incr .eq. 0) then
              if (lmodim) then
                 call utmess('F', 'CONTACT_88')
              endif
           endif
        endif
        if (l_pilo) then
            call utmess('F', 'MECANONLINE3_94')
        endif
        if (l_line_search) then
            call utmess('A', 'MECANONLINE3_95')
        endif
        if (lgcpc .or. lpetsc) then
            call utmess('F', 'MECANONLINE3_96', sk=slvk(1))
        endif
    endif
!
! - Dirichlet undead loads
!
    if (l_diri_undead) then
        if (l_pilo) then
            call utmess('F', 'MECANONLINE5_42')
        endif
        if (l_line_search) then
            call utmess('F', 'MECANONLINE5_39')
        endif
        if (l_dyna) then
            call utmess('F', 'MECANONLINE5_40')
        endif
        if (reac_iter.ne.1) then
            call utmess('F', 'MECANONLINE5_41')
        endif
    endif
!
! - Post-treatment (buckling, ...)
!
    if (l_vibr_mode .or. l_buckling) then
        if (lgcpc .or. lpetsc) then
            call utmess('F', 'FACTOR_52', sk=slvk(1))
        endif
        if (leltc) then
            call utmess('F', 'MECANONLINE5_3')
        endif
    endif
!
! - Explicit solver
!
    if (lexpl) then
        if (l_cont) then
            call utmess('F', 'MECANONLINE5_22')
        endif
        if (l_unil) then
            call utmess('F', 'MECANONLINE5_23')
        endif
        if (l_grot_gdep) then
            call utmess('A', 'MECANONLINE5_24')
        endif
    endif
!
! - Dynamic
!
    if (l_dyna) then
        if (l_comp_rela) then
            call utmess('F', 'MECANONLINE5_53')
        endif
        if (l_pilo) then
            call utmess('F', 'MECANONLINE5_25')
        endif
        if (lxfem) then
            call utmess('F', 'MECANONLINE5_28')
        endif
        if (limpex) then
            call utmess('F', 'MECANONLINE5_33')
        endif
        char24 = ''
        lthms = exi_thms(model, .true._1, char24, 0)
        if (lthms) then
            call utmess('F', 'MECANONLINE5_16')
        endif
    endif
!
! - Continuation methods (PILOTAGE)
!
    if (l_pilo) then
        call getvtx('PILOTAGE', 'TYPE', iocc=1, scal=typilo)
        if (l_line_search) then
            if (typilo .eq. 'DDL_IMPO') then
                call utmess('F', 'MECANONLINE5_34')
            endif
        endif
        if ((matrix_pred.eq.'DEPL_CALCULE') .or. (matrix_pred .eq.'EXTRAPOLE')) then
            call utmess('F', 'MECANONLINE5_36')
        endif
        call dismoi('VARC_F_INST', mate, 'CHAM_MATER', repk=mfdet)
        if (mfdet .eq. 'OUI') then
            call utmess('F', 'CALCULEL2_58', nk=1, valk=mate(1:8))
        endif
    endif
    if (l_line_search) then
        if ((reli_meth.eq.'PILOTAGE') .and. (.not.l_pilo)) then
            call utmess('F', 'MECANONLINE5_35')
        endif
    endif
!
! - NEWTON_KRYLOV
!
    if (l_newt_krylov) then
        if (l_pilo) then
            call utmess('F', 'MECANONLINE5_48')
        endif
        if ((.not.lgcpc) .and. (.not.lpetsc)) then
            call utmess('F', 'MECANONLINE5_51')
        endif
    endif
!
! - ROM
!
    if (l_rom) then
        if (l_pilo) then
            call utmess('F', 'ROM5_69')
        endif
        if (l_line_search) then
            call utmess('F', 'ROM5_34')
        endif
        if (l_dyna) then
            call utmess('F', 'ROM5_70')
        endif
        if (l_cont) then
            call utmess('F', 'ROM5_71')
        endif
    endif
!
! - Energy
!
    if (l_energy) then
        if (lproj) then
            call utmess('F', 'MECANONLINE5_6')
        endif
        if (lmatdi) then
            call utmess('F', 'MECANONLINE5_8')
        endif
        if (leltc) then
            call utmess('F', 'MECANONLINE5_15')
        endif
    endif
!
! --- SI ON A BESOIN DE FACTORISER SIMULTANEMENT DEUX MATRICES AVEC LE SOLVEUR MUMPS ON LUI
!     SIGNALE AFIN QU'IL OPTIMISE AU MIEUX LA MEMOIRE POUR CHACUNES D'ELLES.
!     CE N'EST VRAIMENT UTILE QUE SI SOLVEUR/GESTION_MEMOIRE='AUTO'.
!
    if (l_mumps) then
        if (l_vibr_mode .or. l_buckling) then
            ASSERT(slvi(6) .ge. 0)
            slvi(6)=2
        endif
    endif
!
    call jedema()
!
end subroutine
