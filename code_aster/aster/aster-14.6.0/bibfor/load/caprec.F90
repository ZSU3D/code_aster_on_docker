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

subroutine caprec(load, mesh, ligrmo, vale_type)
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterc/indik8.h"
#include "asterc/r8gaem.h"
#include "asterfort/aflrch.h"
#include "asterfort/armin.h"
#include "asterfort/assert.h"
#include "asterfort/cescar.h"
#include "asterfort/char_rcbp_cabl.h"
#include "asterfort/char_rcbp_lino.h"
#include "asterfort/char_rcbp_sigm.h"
#include "asterfort/chsfus.h"
#include "asterfort/copisd.h"
#include "asterfort/dismoi.h"
#include "asterfort/solide_tran.h"
#include "asterfort/drz12d.h"
#include "asterfort/drz13d.h"
#include "asterfort/exisdg.h"
#include "asterfort/getvid.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetc.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelibe.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenonu.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
!
!
    character(len=8), intent(in) :: load
    character(len=8), intent(in) :: mesh
    character(len=19), intent(in) :: ligrmo
    character(len=4), intent(in) :: vale_type
!
! --------------------------------------------------------------------------------------------------
!
! Loads affectation
!
! Keyword = 'RELA_CINE_BP'
!
! --------------------------------------------------------------------------------------------------
!
!
! In  mesh      : name of mesh
! In  load      : name of load
! In  ligrmo    : list of elements in model
! In  vale_type : affected value type (real, complex or function)
!
! --------------------------------------------------------------------------------------------------
!
    character(len=16) :: keywordfact
    integer :: nliai, ndimmo
    real(kind=8) :: dist_mini, dist
    complex(kind=8) :: cbid
    character(len=8) :: k8bid, model, answer
    integer :: n1, iocc, iret, ibid
    integer :: nbrela
    character(len=19) :: list_rela, list_rela_tmp, list_rela_old
    character(len=2) :: lagr_type
    character(len=8) :: cmp_name
    integer :: dim
    integer :: cmp_index_dx, cmp_index_dy, cmp_index_dz
    integer :: cmp_index_drx, cmp_index_dry, cmp_index_drz
    character(len=8) :: nomg_depl, nomg_sief, nom_noeuds_tmp(4)
    integer :: nb_cmp_depl, nb_cmp_sief
    integer :: j_cmp_depl, j_cmp_sief
    integer :: nbec_depl, nbec_sief
    aster_logical :: l_sigm_bpel, l_rela_cine
    character(len=24) :: list_cabl, list_anc1, list_anc2
    integer :: nb_cabl, nb_anc1, nb_anc2
    integer :: jlicabl, jlianc1, jlianc2
    character(len=24) :: list_node
    integer :: nb_node, jlino
    character(len=8) :: cabl_prec
    character(len=19) :: cabl_sigm
    aster_logical :: l_rota_2d, l_rota_3d
    integer :: i_cabl, i_ancr, i_no, nume_node
    integer :: nb_elem
    integer :: jprnm
    character(len=24) :: name_ancr, name_anc1, name_anc2
    integer :: nume_cabl, nume_cabl0
    integer :: jlces, jll, jlr, nbchs
    integer, pointer :: rlnr(:) => null()
    cbid = dcmplx(0.d0, 0.d0)
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    keywordfact = 'RELA_CINE_BP'
    call getfac(keywordfact, nliai)
    if (nliai .eq. 0) goto 999
!
! - Initializations
!
    list_node = '&&CAPREC.LIST_NODE'
    list_rela = '&&CAPREC.RLLISTE'
    list_cabl = '&&CAPREC.LIST_CABL'
    list_anc1 = '&&CAPREC.LIST_ANC1'
    list_anc2 = '&&CAPREC.LIST_ANC2'
    list_rela = '&&CAPREC.LIRELA'
    list_rela_tmp = '&&CAPREC.LIRELA_TMP'
    cabl_sigm = load//'.CHME.SIGIN'
    model = ligrmo(1:8)
!
    call wkvect('&&CAPREC.LCES', 'V V K16', nliai, jlces)
    call wkvect('&&CAPREC.LCESL', 'V V L', nliai, jll)
    call wkvect('&&CAPREC.LCESR', 'V V R', nliai, jlr)
    nbchs=0
!
    call dismoi('DIM_GEOM', model, 'MODELE', repi=ndimmo)
    call dismoi('NB_MA_MAILLA', mesh, 'MAILLAGE', repi=nb_elem)
    if (.not.(ndimmo.eq.2.or.ndimmo.eq.3)) then
        call utmess('F', 'CHARGES2_6')
    endif
!
! - Initializations of types
!
    lagr_type = '12'
    ASSERT(vale_type.eq.'REEL')
!
! - Minimum distance
!
    dist = armin(mesh)
!
! - Information about DEPL_R  <GRANDEUR>
!
    nomg_depl = 'DEPL_R'
    call jeveuo(jexnom('&CATA.GD.NOMCMP', nomg_depl), 'L', j_cmp_depl)
    call jelira(jexnom('&CATA.GD.NOMCMP', nomg_depl), 'LONMAX', nb_cmp_depl, k8bid)
    call dismoi('NB_EC', nomg_depl, 'GRANDEUR', repi=nbec_depl)
    ASSERT(nbec_depl.le.10)
    call jeveuo(ligrmo//'.PRNM', 'L', jprnm)
!
! - Index in DEPL_R <GRANDEUR> for DX, DY, DZ, DRX, DRY, DRZ
!
    cmp_name = 'DX'
    cmp_index_dx = indik8(zk8(j_cmp_depl), cmp_name, 1, nb_cmp_depl)
    ASSERT(cmp_index_dx.gt.0)
    cmp_name = 'DY'
    cmp_index_dy = indik8(zk8(j_cmp_depl), cmp_name, 1, nb_cmp_depl)
    ASSERT(cmp_index_dy.gt.0)
    cmp_name = 'DZ'
    cmp_index_dz = indik8(zk8(j_cmp_depl), cmp_name, 1, nb_cmp_depl)
    ASSERT(cmp_index_dz.gt.0)
    cmp_name = 'DRX'
    cmp_index_drx = indik8(zk8(j_cmp_depl), cmp_name, 1, nb_cmp_depl)
    ASSERT(cmp_index_drx.gt.0)
    cmp_name = 'DRY'
    cmp_index_dry = indik8(zk8(j_cmp_depl), cmp_name, 1, nb_cmp_depl)
    ASSERT(cmp_index_dry.gt.0)
    cmp_name = 'DRZ'
    cmp_index_drz = indik8(zk8(j_cmp_depl), cmp_name, 1, nb_cmp_depl)
    ASSERT(cmp_index_drz.gt.0)
!
! - Information about SIEF_R  <GRANDEUR>
!
    nomg_sief = 'SIEF_R'
    call jeveuo(jexnom('&CATA.GD.NOMCMP', nomg_sief), 'L', j_cmp_sief)
    call jelira(jexnom('&CATA.GD.NOMCMP', nomg_sief), 'LONMAX', nb_cmp_sief, k8bid)
    call dismoi('NB_EC', nomg_sief, 'GRANDEUR', repi=nbec_sief)
    ASSERT(nbec_sief.le.10)
!
    do iocc = 1, nliai
!
! ----- Minimum distance
!
        call getvr8(keywordfact, 'DIST_MIN', iocc=iocc, scal=dist_mini, nbret=n1)
        if (n1 .eq. 0) dist_mini = dist*1.d-3
!
! ----- Options
!
        call getvtx(keywordfact, 'SIGM_BPEL', iocc=iocc, scal=answer, nbret=ibid)
        l_sigm_bpel = (answer.eq.'OUI')
        call getvtx(keywordfact, 'RELA_CINE', iocc=iocc, scal=answer, nbret=ibid)
        l_rela_cine = (answer.eq.'OUI')
!
        if (l_sigm_bpel .or. l_rela_cine) then
!
            call getvid(keywordfact, 'CABLE_BP', iocc=iocc, scal=cabl_prec, nbret=ibid)
!
! --------- Get and combine stresses
!
            if (l_sigm_bpel) then
                call char_rcbp_sigm(cabl_prec, iocc, nbchs, jlces, jll,&
                                    jlr)
            endif
!
! --------- Linear relations
!
            if (l_rela_cine) then
                list_rela_old = cabl_prec//'.LIRELA'
                call jeexin(list_rela_old//'.RLNR', iret)
                if (iret .eq. 0) then
                    call utmess('F', 'CHARGES2_48', sk=cabl_prec)
                endif
!
! ------------- Get old linear relations
!
                call jeveuo(list_rela_old//'.RLNR', 'L', vi=rlnr)
                nbrela = rlnr(1)
                call jelibe(list_rela_old//'.RLNR')
                if (nbrela .gt. 0) then
                    call copisd(' ', 'V', list_rela_old, list_rela_tmp)
                    call aflrch(list_rela_tmp, load, 'NLIN')
                endif
!
! ------------  Get information about cables
!
                call char_rcbp_cabl(cabl_prec, list_cabl, list_anc1, list_anc2, nb_cabl,&
                                    nb_anc1, nb_anc2)
                call jeveuo(list_cabl, 'L', jlicabl)
                call jeveuo(list_anc1, 'L', jlianc1)
                call jeveuo(list_anc2, 'L', jlianc2)
!
! ------------- Set linear relations for cables
!
                nume_cabl0 = 0
                name_ancr = ' '
                do i_cabl = 1, nb_cabl
                    nume_cabl = zi(jlicabl-1+i_cabl)
                    name_anc1 = zk24(jlianc1-1+i_cabl)
                    name_anc2 = zk24(jlianc2-1+i_cabl)
                    if (nume_cabl .ne. nume_cabl0) then
                        nume_cabl0 = nume_cabl
                        do i_ancr = 1, 2
                            name_ancr = ' '
                            if (i_ancr .eq. 1) name_ancr = name_anc1
                            if (i_ancr .eq. 2) name_ancr = name_anc2
                            if (name_ancr .ne. ' ') then
!
! ------------------------------Get list of nodes for ancrage
!
                                call char_rcbp_lino(mesh, name_ancr, list_node, nb_node)
                                call jeveuo(list_node, 'L', jlino)
                                if (nb_node .eq. 1) then
                                    call utmess('I', 'CHARGES2_17')
                                    goto 140
                                endif
!
! ----------------------------- Set LIAISON_SOLIDE for ndim =2
!
                                if (ndimmo .eq. 2) then
!
! --------------------------------- Is any node has rotation dof ?
!
                                    l_rota_2d = .false.
                                    do i_no = 1, nb_node
                                        nume_node = zi(jlino+i_no-1)
                                        if (exisdg(&
                                            zi(jprnm-i_no+(nume_node-1)*nbec_depl+1),&
                                            cmp_index_drz&
                                            )) then
                                            l_rota_2d = .true.
                                            goto 110
                                        endif
                                    enddo
110                                 continue
!
! --------------------------------- Compute linear relations
!
                                    if (l_rota_2d) then
                                        call drz12d(mesh, ligrmo, vale_type, nb_node, list_node,&
                                                    cmp_index_drz, lagr_type, list_rela,&
                                                    nom_noeuds_tmp)
                                    else
                                        call solide_tran('2D',mesh, vale_type, dist_mini, nb_node,&
                                                         list_node, lagr_type, list_rela,&
                                                         nom_noeuds_tmp, dim)
                                    endif
!
! ----------------------------- Set LIAISON_SOLIDE for ndim = 3
!
                                else if (ndimmo.eq.3) then
!
! --------------------------------- Is any node has rotation dof ?
!
                                    l_rota_3d = .false.
                                    do i_no = 1, nb_node
                                        nume_node = zi(jlino+i_no-1)
                                        if (exisdg(&
                                            zi(jprnm-1+(nume_node-1)*nbec_depl+1),&
                                            cmp_index_drx&
                                            )&
                                            .and.&
                                            exisdg(&
                                            zi(jprnm-1+(nume_node-1)*nbec_depl+1),&
                                            cmp_index_dry&
                                            )&
                                            .and.&
                                            exisdg(&
                                            zi(jprnm-1+(nume_node-1)*nbec_depl+1),&
                                            cmp_index_drz&
                                            )) then
                                            l_rota_3d = .true.
                                            goto 120
                                        endif
                                    enddo
120                                 continue
!
! --------------------------------- Compute linear relations
!
                                    if (l_rota_3d) then
                                        call drz13d(mesh, ligrmo, vale_type, nb_node, list_node,&
                                                    cmp_index_dx, cmp_index_dy, cmp_index_dz,&
                                                    cmp_index_drx, cmp_index_dry, cmp_index_drz,&
                                                    lagr_type, list_rela, nom_noeuds_tmp)
                                    else
                                        call solide_tran('3D',mesh, vale_type, dist_mini, nb_node,&
                                                         list_node, lagr_type, list_rela,&
                                                         nom_noeuds_tmp, dim)
                                    endif
                                else
                                    ASSERT(.false.)
                                endif
                                call jedetr(list_node)
                                call aflrch(list_rela, load, 'NLIN', elim='NON')
                            endif
140                         continue
                        enddo
                    endif
                enddo
                call jedetr(list_cabl)
                call jedetr(list_anc1)
                call jedetr(list_anc2)
            endif
        endif
    enddo
!
! - Fusion des champs et transformation en carte
!
    if (nbchs .gt. 0) then
        call chsfus(nbchs, zk16(jlces), zl(jll), zr(jlr), [cbid],&
                    .false._1, 'V', '&&CAPREC.CES')
        call cescar('&&CAPREC.CES', cabl_sigm, 'G')
    endif
!
    call jedetc('V', '&&CAPREC.CES', 1)
!
999 continue
    call jedema()
end subroutine
