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
! person_in_charge: samuel.geniaut at edf.fr
!
subroutine xmmbca(mesh, model, ds_material, hval_incr, ds_contact,&
                  ds_constitutive, list_func_acti)
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/calcul.h"
#include "asterfort/copisd.h"
#include "asterfort/dbgcal.h"
#include "asterfort/infdbg.h"
#include "asterfort/isfonc.h"
#include "asterfort/inical.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mesomm.h"
#include "asterfort/mmbouc.h"
#include "asterfort/nmchex.h"
#include "asterfort/xmchex.h"
!
character(len=8), intent(in) :: mesh
character(len=8), intent(in) :: model
type(NL_DS_Material), intent(in) :: ds_material
character(len=19), intent(in) :: hval_incr(*)
type(NL_DS_Contact), intent(inout) :: ds_contact
type(NL_DS_Constitutive), intent(in) :: ds_constitutive
integer, intent(in) :: list_func_acti(*)
!
! --------------------------------------------------------------------------------------------------
!
! Contact - Solve
!
! XFEM - Management of contact loop
!
! --------------------------------------------------------------------------------------------------
!
! In  mesh             : name of mesh
! In  model            : name of model
! In  ds_material      : datastructure for material parameters
! In  hval_incr        : hat-variable for incremental values fields
! IO  ds_contact       : datastructure for contact management
! In  ds_constitutive  : datastructure for constitutive laws management
! In  list_func_acti   : list of active functionnalities 
!
! --------------------------------------------------------------------------------------------------
!
    integer, parameter :: nbout = 4
    integer, parameter :: nbin  = 25
    character(len=8) :: lpaout(nbout), lpain(nbin)
    character(len=19) :: lchout(nbout), lchin(nbin)
!
    integer :: sinco(1)
    integer :: jfiss
    character(len=19) :: xdonco, xindco, xmemco, xgliss, xcohes, ccohes
    character(len=16) :: option
    character(len=19) :: ligrmo, cicoca, cindoo, cmemco, ltno
    character(len=19) :: pinter, ainter, cface, faclon, baseco, xcoheo, lnno, stano
    character(len=19) :: fissno, heavno, heavfa, hea_no, hea_fa, fisco, baslo
    aster_logical :: debug, lcontx, lxthm
    integer :: ifm, niv, ifmdbg, nivdbg
    character(len=19) :: oldgeo, depmoi, depplu
    aster_logical :: loop_cont_conv
    integer, pointer :: xfem_cont(:) => null()
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    call infdbg('XFEM', ifm, niv)
    call infdbg('PRE_CALCUL', ifmdbg, nivdbg)
!
! --- INITIALISATIONS
!
    oldgeo = mesh(1:8)//'.COORDO'
    ligrmo = model(1:8)//'.MODELE'
    cicoca = '&&XMMBCA.CICOCA'
    cindoo = '&&XMMBCA.INDOUT'
    cmemco = '&&XMMBCA.MEMCON'
    ccohes = '&&XMMBCA.COHES'
!
    xindco = ds_contact%sdcont_solv(1:14)//'.XFIN'
    xdonco = ds_contact%sdcont_solv(1:14)//'.XFDO'
    xmemco = ds_contact%sdcont_solv(1:14)//'.XMEM'
    xgliss = ds_contact%sdcont_solv(1:14)//'.XFGL'
    xcohes = ds_contact%sdcont_solv(1:14)//'.XCOH'
    xcoheo = ds_contact%sdcont_solv(1:14)//'.XCOP'
!
    loop_cont_conv = ASTER_FALSE
    debug = nivdbg .ge. 2
!
! --- DECOMPACTION DES VARIABLES CHAPEAUX
!
    call nmchex(hval_incr, 'VALINC', 'DEPMOI', depmoi)
    call nmchex(hval_incr, 'VALINC', 'DEPPLU', depplu)
!
! --- SI PAS DE CONTACT ALORS ON ZAPPE LA VÉRIFICATION
!
    call jeveuo(model(1:8)//'.XFEM_CONT', 'L', vi=xfem_cont)
    lcontx = xfem_cont(1) .ge. 1
    if (.not.lcontx) then
        loop_cont_conv = .true.
        goto 999
    endif
!
! --- DETERMINATION DE L OPTION
!
    if(xfem_cont(1).eq.1.or.xfem_cont(1).eq.3) option='XCVBCA'
    if(xfem_cont(1).eq.2) option='XCVBCA_MORTAR'
!
! --- MODELE HM-XFEM ?
!
    lxthm = isfonc(list_func_acti,'THM')
!
! --- INITIALISATION DES CHAMPS POUR CALCUL
!
    call inical(nbin, lpain, lchin, nbout, lpaout,&
                lchout)
!
! --- ACCES A LA SD FISS_XFEM
!
    call jeveuo(model(1:8)//'.FISS', 'L', jfiss)
!
! --- RECUPERATION DES DONNEES XFEM
!
    ltno = model(1:8)//'.LTNO'
    pinter = model(1:8)//'.TOPOFAC.OE'
    ainter = model(1:8)//'.TOPOFAC.AI'
    cface = model(1:8)//'.TOPOFAC.CF'
    faclon = model(1:8)//'.TOPOFAC.LO'
    baseco = model(1:8)//'.TOPOFAC.BA'
    fissno = model(1:8)//'.FISSNO'
    heavno = model(1:8)//'.HEAVNO'
    heavfa = model(1:8)//'.TOPOFAC.HE'
    hea_no = model(1:8)//'.TOPONO.HNO'
    hea_fa = model(1:8)//'.TOPONO.HFA'
    stano = model(1:8)//'.STNO'
    fisco = model(1:8)//'.FISSCO'
    lnno = model(1:8)//'.LNNO'
    baslo = model(1:8)//'.BASLOC'
!
! --- CREATION DU CHAM_ELEM_S VIERGE  INDIC. CONTACT ET MEMOIRE CONTACT
!
    if (lxthm .and. xfem_cont(1).eq.3) then
       call xmchex(mesh, xcoheo, ccohes)
    else if (.not.lxthm) then
       call xmchex(mesh, xindco, cindoo)
       call xmchex(mesh, xmemco, cmemco)
       if(xfem_cont(1).eq.1.or.xfem_cont(1).eq.3)&
           call xmchex(mesh, xcohes, ccohes)
    endif
!
! --- CREATION DES LISTES DES CHAMPS IN
!
    lpain(1) = 'PGEOMER'
    lchin(1) = oldgeo(1:19)
    lpain(2) = 'PDEPL_M'
    lchin(2) = depmoi(1:19)
    lpain(3) = 'PDEPL_P'
    lchin(3) = depplu(1:19)
    lpain(4) = 'PINDCOI'
    lchin(4) = xindco
    lpain(5) = 'PLST'
    lchin(5) = ltno
    lpain(6) = 'PPINTER'
    lchin(6) = pinter
    lpain(7) = 'PAINTER'
    lchin(7) = ainter
    lpain(8) = 'PCFACE'
    lchin(8) = cface
    lpain(9) = 'PLONGCO'
    lchin(9) = faclon
    lpain(10) = 'PDONCO'
    lchin(10) = xdonco
    lpain(11) = 'PGLISS'
    lchin(11) = xgliss
    lpain(12) = 'PMEMCON'
    lchin(12) = xmemco
    lpain(13) = 'PCOHES'
    lchin(13) = xcohes
    lpain(14) = 'PBASECO'
    lchin(14) = baseco
    lpain(15) = 'PMATERC'
    lchin(15) = ds_material%field_mate(1:19)
    lpain(16) = 'PFISNO'
    lchin(16) = fissno
    lpain(17) = 'PHEAVNO'
    lchin(17) = heavno
    lpain(18) = 'PHEAVFA'
    lchin(18) = heavfa
    lpain(19) = 'PCOMPOR'
    lchin(19) = ds_constitutive%compor(1:19)
    lpain(20) = 'PHEA_NO'
    lchin(20) = hea_no
    lpain(21) = 'PHEA_FA'
    lchin(21) = hea_fa
    lpain(22) = 'PFISCO'
    lchin(22) = fisco
    lpain(23) = 'PLSN'
    lchin(23) = lnno
    lpain(24) = 'PSTANO'
    lchin(24) = stano
    lpain(25) = 'PBASLOR'
    lchin(25) = baslo
!
! --- CREATION DES LISTES DES CHAMPS OUT
!
    lpaout(1) = 'PINCOCA'
    lchout(1) = cicoca
    lpaout(2) = 'PINDCOO'
    lchout(2) = cindoo
    lpaout(3) = 'PINDMEM'
    lchout(3) = cmemco
    lpaout(4) = 'PCOHESO'
    lchout(4) = ccohes
!
! --- APPEL A CALCUL
!
    call calcul('S', option, ligrmo, nbin, lchin,&
                lpain, nbout, lchout, lpaout, 'V',&
                'OUI')
!
    if (debug) then
        call dbgcal(option, ifmdbg, nbin, lpain, lchin,&
                    nbout, lpaout, lchout)
    endif
!
! --- ON FAIT sinco(1) = SOMME DES CICOCA SUR LES ÉLTS DU LIGRMO
!
    call mesomm(cicoca, 1, vi=sinco(1))
!
! --- SI sinco(1) EST STRICTEMENT POSITIF, ALORS ON A EU UN CODE RETOUR
! --- SUPERIEUR A ZERO SUR UN ELEMENT ET DONC ON A PAS CONVERGÉ
!
    if (sinco(1) .gt. 0) then
        loop_cont_conv = .false.
    else
        loop_cont_conv = .true.
    endif
!
! --- ON COPIE CINDO DANS RESOCO.XFIN
!
    call copisd('CHAMP_GD', 'V', lchout(2), xindco)
!
! --- ON COPIE CMEMCO DANS RESOCO.XMEM
!
    call copisd('CHAMP_GD', 'V', lchout(3), xmemco)
    call copisd('CHAMP_GD', 'V', lchout(4), xcohes)
!
999 continue
!
! - Set loop values
!
    if (loop_cont_conv) then
        call mmbouc(ds_contact, 'Cont', 'Set_Convergence')
    else
        call mmbouc(ds_contact, 'Cont', 'Set_Divergence')
    endif
!
    call jedema()
end subroutine
