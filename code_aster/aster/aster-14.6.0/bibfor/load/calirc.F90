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
! aslint: disable=W1501
! Person in charge: mickael.abbas at edf.fr
!
subroutine calirc(phenom_, load, mesh)
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterfort/aflrch.h"
#include "asterfort/afrela.h"
#include "asterfort/assert.h"
#include "asterfort/calir3.h"
#include "asterfort/calir4.h"
#include "asterfort/calir5.h"
#include "asterfort/calirg.h"
#include "asterfort/canort.h"
#include "asterfort/char_read_tran.h"
#include "asterfort/createTabRela.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvtx.h"
#include "asterfort/imprel.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jedupo.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/nbnlma.h"
#include "asterfort/pj2dco.h"
#include "asterfort/pj3dco.h"
#include "asterfort/pj4dco.h"
#include "asterfort/reliem.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/getvr8.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
#include "asterfort/checkModelOnElements.h"
!
character(len=*), intent(in) :: phenom_
character(len=8), intent(in) :: load
character(len=8), intent(in) :: mesh
!
! --------------------------------------------------------------------------------------------------
!
! Loads affectation
!
! Keyword = 'LIAISON_MAIL'
!
! --------------------------------------------------------------------------------------------------
!
! In  phenom       : phenomenon (MECANIQUE/THERMIQUE/ACOUSTIQUE)
! In  load         : name of load
! In  mesh         : name of mesh
!
! --------------------------------------------------------------------------------------------------
!
    integer :: k, kk, nuno1, nuno2, ino1, ino2, ndim, nocc, iocc
    integer :: ibid, nnomx, idmax, igeom
    integer :: iagno2, nbma1, nbno2, nbno2t
    integer :: nno1, i, lno
    integer :: jconb, jconu, jcocf, idecal
    integer :: jconb1, jconu1, jcocf1, jcom11, ideca1
    integer :: jconb2, jconu2, jcocf2, jcom12, ideca2
    integer :: nbtyp, nddl2, nbma2, jlistk, jdim, ndim1
    integer :: jnorm, idim, ij, ima1, jlisv1
    integer :: kno2, kkno2, jcoor, n1, nb_found
    aster_logical :: lrota, dnor
    real(kind=8) :: beta, coef1, mrota(3, 3), zero, normal(3)
    complex(kind=8) :: betac
    complex(kind=8), parameter :: cbid = dcmplx(0.d0, 0.d0)
    character(len=2) :: typlag
    character(len=4) :: fonree
    character(len=4) :: typcoe, typlia
    character(len=8) :: model, m8blan, kelim, liaison_epx
    character(len=8) :: kbeta, nono1, nono2, cmp, ddl2, listyp(8)
    character(len=16) :: motfac, tymocl(4), motcle(4)
    character(len=16) :: corres, corre1, corre2, typrac
    character(len=19) :: lisrel
    character(len=24) :: geom2
    character(len=24) :: valk(2)
    aster_logical :: l_tran
    real(kind=8) :: tran(3)
    aster_logical :: l_cent
    real(kind=8) :: cent(3), dmax, dala
    aster_logical :: l_angl_naut, l_dmax
    real(kind=8) :: angl_naut(3)
    character(len=24) :: list_node
    integer, pointer :: limanu1(:) => null()
    integer, pointer :: ln(:) => null()
    integer, pointer :: limanu2(:) => null()
    integer, pointer :: com1(:) => null()
    real(kind=8), pointer :: coef(:) => null()
    integer, pointer :: dim(:) => null()
    real(kind=8), pointer :: direct(:) => null()
    integer, pointer :: elim(:) => null()
    integer, pointer :: vindire(:) => null()
    integer, pointer :: linonu2bis(:) => null()
    character(len=8), pointer :: nomddl(:) => null()
    character(len=8), pointer :: nomnoe(:) => null()
    character(len=16), pointer :: v_list_type(:) => null()
    aster_logical :: l_error, detr_lisrel
    character(len=8) :: elem_error
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
    motfac='LIAISON_MAIL'
    call getfac(motfac, nocc)
    if (nocc .eq. 0) goto 320
!
    if (phenom_ .eq. 'MECANIQUE') then
        typlia='DEPL'
    else if (phenom_ .eq.'THERMIQUE') then
        typlia='TEMP'
    else
        ASSERT(.false.)
    endif
!
    fonree='REEL'
    typcoe='REEL'
!
    lisrel='&&CALIRC.RLLISTE'
    zero=0.0d0
    beta=0.0d0
    betac=(0.0d0,0.0d0)
    kbeta=' '
    typlag='12'
    m8blan='        '
    ndim1=3
!
    call dismoi('NOM_MODELE', load, 'CHARGE', repk=model)
    call dismoi('DIM_GEOM', model, 'MODELE', repi=igeom)
    if (.not.(igeom.eq.2.or.igeom.eq.3)) then
        call utmess('F', 'MODELISA2_6')
    endif
    if (igeom .eq. 2) then
        ndim=2
    else
        ndim=3
    endif
!
    if (ndim .eq. 2) then
        nbtyp=3
        listyp(1)='SEG2'
        listyp(2)='SEG3'
        listyp(3)='SEG4'
    else if (ndim.eq.3) then
        nbtyp=8
        listyp(1)='TRIA3'
        listyp(2)='TRIA6'
        listyp(3)='QUAD4'
        listyp(4)='QUAD8'
        listyp(5)='QUAD9'
        listyp(6)='SEG2'
        listyp(7)='SEG3'
        listyp(8)='SEG4'
    endif
!
    call dismoi('NB_NO_MAILLA', mesh, 'MAILLAGE', repi=nnomx)
!     -- IDMAX : NOMBRE MAX DE TERMES D'UNE RELATION LINEAIRE
!              = 2*27 + 3 = 57
    idmax=57
    AS_ALLOCATE(vk8=nomnoe, size=idmax)
    AS_ALLOCATE(vk8=nomddl, size=idmax)
    AS_ALLOCATE(vr=coef, size=idmax)
    AS_ALLOCATE(vr=direct, size=idmax*3)
    AS_ALLOCATE(vi=dim, size=idmax)
!
!
!     &&CALIRC.ELIM(INO) : 0 -> INO PAS ELIMINE
!                          1 -> INO ELIMINE
    AS_ALLOCATE(vi=elim, size=nnomx)
!
    corres='&&CALIRC.CORRES'
    corre1='&&CALIRC.CORRE1'
    corre2='&&CALIRC.CORRE2'
!
    do iocc = 1, nocc
!
!       IL FAUT REMETTRE à ZERO CES 2 OBJETS ENTRE 2 OCCURENCES :
        do kk = 1, idmax
            dim(kk)=0
        end do
        do kk = 1, 3*idmax
            direct(kk)=0.d0
        end do
!
        dnor=.false.
        typrac=' '
        if (typlia .eq. 'DEPL') then
            call getvtx(motfac, 'DDL_ESCL', iocc=iocc, scal=ddl2, nbret=nddl2)
            if (nddl2 .gt. 0) dnor=.true.
            call getvtx(motfac, 'TYPE_RACCORD', iocc=iocc, scal=typrac, nbret=ibid)
            if (typrac .eq. 'COQUE') then
                ASSERT(ndim.eq.3)
            endif
            if (typrac .eq. 'COQUE_MASSIF') then
                ASSERT(ndim.eq.3)
            endif
            if (typrac .eq. 'MASSIF_COQUE') then
                ASSERT(ndim.eq.3)
            endif
        endif
!
!        1.1 RECUPERATION DE LA LISTE DES MAILLE_MAIT :
!        ----------------------------------------------
        motcle(1)='MAILLE_MAIT'
        tymocl(1)='MAILLE'
        motcle(2)='GROUP_MA_MAIT'
        tymocl(2)='GROUP_MA'
        call reliem(model, mesh, 'NU_MAILLE', motfac, iocc,&
                    2, motcle, tymocl, '&&CALIRC.LIMANU1', nbma1)
        call jeveuo('&&CALIRC.LIMANU1', 'L', vi=limanu1)
!
!
!        1.2 RECUPERATION DES NOEUD_ESCL
!        -------------------------------
        if (.not.dnor) then
!
!        -- RECUPERATION DE LA LISTE DES NOEUD_ESCL :
!        --------------------------------------------
            motcle(1)='NOEUD_ESCL'
            tymocl(1)='NOEUD'
            motcle(2)='GROUP_NO_ESCL'
            tymocl(2)='GROUP_NO'
            motcle(3)='MAILLE_ESCL'
            tymocl(3)='MAILLE'
            motcle(4)='GROUP_MA_ESCL'
            tymocl(4)='GROUP_MA'
            call reliem(' ', mesh, 'NU_NOEUD', motfac, iocc,&
                        4, motcle, tymocl, '&&CALIRC.LINONU2', nbno2)
            call jeveuo('&&CALIRC.LINONU2', 'L', iagno2)
!
        else
!
!        -- RECUPERATION DE LA LISTE DES MAILLE_ESCL :
!        ---------------------------------------------
            motcle(1)='MAILLE_ESCL'
            tymocl(1)='MAILLE'
            motcle(2)='GROUP_MA_ESCL'
            tymocl(2)='GROUP_MA'
            call reliem(model, mesh, 'NU_MAILLE', motfac, iocc,&
                        2, motcle, tymocl, '&&CALIRC.LIMANU2', nbma2)
            if (nbma2 .eq. 0) then
                valk(1)=motcle(1)
                valk(2)=motcle(2)
                call utmess('F', 'MODELISA8_49', nk=2, valk=valk)
            endif
            call jeveuo('&&CALIRC.LIMANU2', 'L', vi=limanu2)
!
! ---        CREATION DU TABLEAU DES NUMEROS DES NOEUDS '&&NBNLMA.LN'
! ---        ET DES NOMBRES D'OCCURENCES DE CES NOEUDS '&&NBNLMA.NBN'
! ---        DES MAILLES DE PEAU MAILLE_ESCL :
!            -------------------------------
            call nbnlma(mesh , nbma2, limanu2, nbtyp, listyp,&
                        nbno2, l_error, elem_error)
            if (l_error) then
                call utmess('F', 'CHARGES6_4', sk = elem_error)
            endif
!
! ---        CALCUL DES NORMALES EN CHAQUE NOEUD :
!            -----------------------------------
            call wkvect('&&CALIRC.LISTK', 'V V K8', 1, jlistk)
            call jeveuo('&&NBNLMA.LN', 'L', vi=ln)
!
! ---        CREATION DU TABLEAU D'INDIRECTION ENTRE LES INDICES
! ---        DU TABLEAU DES NORMALES ET LES NUMEROS DES NOEUDS :
!            -------------------------------------------------
            AS_ALLOCATE(vi=vindire, size=nnomx)
            call jelira('&&NBNLMA.LN', 'LONUTI', lno)
!
            do i = 1, lno
                vindire(1+ln(i)-1)=i
            end do
!
            call canort(mesh, nbma2, limanu2, ndim, nbno2,&
                        ln, 1)
            call jeveuo('&&CANORT.NORMALE', 'L', jnorm)
            call jedupo('&&NBNLMA.LN', 'V', '&&CALIRC.LINONU2', .false._1)
            call jeveuo('&&CALIRC.LINONU2', 'L', iagno2)
        endif
!
!
!       1.3 ON ELIMINE DE LINONU2 LES NOEUDS DEJA ELIMINES LORS DES
!           OCCURENCES PRECEDENTES DE LIAISON_MAILLE
!       ---------------------------------------------------------------
        call getvtx(motfac, 'ELIM_MULT', iocc=iocc, scal=kelim, nbret=ibid)
        if (kelim .eq. 'NON') then
            kkno2=0
            AS_ALLOCATE(vi=linonu2bis, size=nbno2)
            do kno2 = 1, nbno2
                nuno2=zi(iagno2-1+kno2)
!            -- SI NUNO2 N'EST PAS ENCORE ELIMINE :
                if (elim(nuno2) .eq. 0) then
                    elim(nuno2)=1
                    kkno2=kkno2+1
                    linonu2bis(kkno2)=nuno2
                endif
            end do
            nbno2=kkno2
            if (nbno2.eq.0) call utmess('F','MODELISA8_48',si=iocc)
            call jedetr('&&CALIRC.LINONU2')
            call wkvect('&&CALIRC.LINONU2', 'V V I', nbno2, iagno2)
            do kno2 = 1, nbno2
                zi(iagno2-1+kno2)=linonu2bis(kno2)
            end do
            AS_DEALLOCATE(vi=linonu2bis)
        endif
!
!
!       1.4 TRANSFORMATION DE LA GEOMETRIE DE GRNO2 :
!       ------------------------------------------
!
!
! ----- Read transformation
!
        call char_read_tran(motfac, iocc, ndim, l_tran, tran,&
                            l_cent, cent, l_angl_naut, angl_naut)
!
! ----- Apply trasnformation
!
        geom2='&&CALIRC.GEOM_TRANSF'
        list_node = '&&CALIRC.LINONU2'
        call calirg(mesh, nbno2, list_node, tran, cent,&
                    l_angl_naut, angl_naut, geom2, lrota, mrota)
!
!       -- LROTA = .TRUE. : ON A UTILISE LE MOT CLE ANGL_NAUT
        if (typrac .eq. 'COQUE_MASSIF') then
            ASSERT(.not.lrota)
        endif
        if (typrac .eq. 'MASSIF_COQUE') then
            ASSERT(.not.lrota)
        endif
        if (typrac .eq. 'COQUE') then
            ASSERT(.not.lrota)
        endif
!

!       1.5 Calcul de dmax, l_dmax et dala :
!       ------------------------------------
        dmax=0.d0
        call getvr8(motfac, 'DISTANCE_MAX', iocc=iocc, scal=dmax, nbret=n1)
        l_dmax=n1.eq.1
        call getvr8(motfac, 'DISTANCE_ALARME', iocc=iocc, scal=dala, nbret=n1)
        if (n1.eq.0) dala=-1.d0
!
!
!       2. CALCUL DE CORRES (+ EVENTUELLEMENT CORRE1, CORRE2) :
!       --------------------------------------------------------
        if (ndim .eq. 2) then
            ASSERT((typrac.eq.' ') .or. (typrac.eq.'MASSIF'))
            call pj2dco('PARTIE', model, model, nbma1, limanu1,&
                        nbno2, zi( iagno2), ' ', geom2, corres,&
                        l_dmax, dmax, dala)
        else if (ndim.eq.3) then
            if ((typrac.eq.' ') .or. (typrac.eq.'MASSIF')) then
                call pj3dco('PARTIE', model, model, nbma1, limanu1,&
                            nbno2, zi(iagno2), ' ', geom2, corres,&
                            l_dmax, dmax, dala)
            elseif (typrac.eq.'COQUE' .or. typrac.eq.'MASSIF_COQUE') then
                call pj4dco('PARTIE', model, model, nbma1, limanu1,&
                            nbno2, zi(iagno2), ' ', geom2, corres,&
                            l_dmax, dmax, dala)
            else if (typrac.eq.'COQUE_MASSIF') then
                call pj3dco('PARTIE', model, model, nbma1, limanu1,&
                            nbno2, zi(iagno2), ' ', geom2, corres,&
                            l_dmax, dmax, dala)
                call wkvect('&&CALIRC.LISV1', 'V V R', 3*nnomx, jlisv1)
                call calir3(model, nbma1, limanu1, nbno2, zi(iagno2),&
                            geom2, corre1, corre2, jlisv1, iocc)
            else
                ASSERT(.false.)
            endif
!
        endif
!
! ----- No COQUE_3D with MASSIF_COQUE
!
        if (typrac.eq.'MASSIF_COQUE') then
            AS_ALLOCATE(vk16 = v_list_type, size = 2)
            v_list_type(1) = 'MEC3TR7H'
            v_list_type(2) = 'MEC3QU9H'
            call checkModelOnElements(model,&
                            nbma1, limanu1,&
                            2, v_list_type,&
                            nb_found)
            if (nb_found .ne. 0) then
                call utmess('F', 'CHARGES6_6')
            endif
            AS_DEALLOCATE(vk16 = v_list_type)
        endif
!
        call jeveuo(corres//'.PJEF_NB', 'L', jconb)
        call jeveuo(corres//'.PJEF_M1', 'L', vi=com1)
        call jeveuo(corres//'.PJEF_NU', 'L', jconu)
        call jeveuo(corres//'.PJEF_CF', 'L', jcocf)
!
        if (typrac .eq. 'COQUE_MASSIF') then
            call jeveuo(corre1//'.PJEF_NB', 'L', jconb1)
            call jeveuo(corre1//'.PJEF_M1', 'L', jcom11)
            call jeveuo(corre1//'.PJEF_NU', 'L', jconu1)
            call jeveuo(corre1//'.PJEF_CF', 'L', jcocf1)
            call jeveuo(corre2//'.PJEF_NB', 'L', jconb2)
            call jeveuo(corre2//'.PJEF_M1', 'L', jcom12)
            call jeveuo(corre2//'.PJEF_NU', 'L', jconu2)
            call jeveuo(corre2//'.PJEF_CF', 'L', jcocf2)
        endif
        call jelira(corres//'.PJEF_NB', 'LONMAX', nbno2t)
        ASSERT(nbno2t.eq.nnomx)
!
!
!
!       3. ECRITURE DES RELATIONS LINEAIRES :
!       =====================================
!
!
!       3.1 CAS "DEPL" :
!       =================
        if (typlia .eq. 'DEPL') then
!
!       -- 3.1.1 S'IL N'Y A PAS DE ROTATION :
!       -------------------------------------
            if (.not.lrota) then
                idecal=0
                ideca1=0
                ideca2=0
!
!           -- ON BOUCLE SUR TOUS LES NOEUDS DU MAILLAGE :
                do ino2 = 1, nbno2t
!             IMA1: MAILLE A CONNECTER A INO2
                    ima1=com1(ino2)
!             -- SI IMA1=0, C'EST QUE INO2 NE FAIT PAS PARTIE
!                DES NOEUDS ESCLAVES
                    if (ima1 .eq. 0) goto 140
!
!             NNO1: NB NOEUDS DE IMA1
                    nno1=zi(jconb-1+ino2)
!
                    nuno2=ino2
                    call jenuno(jexnum(mesh//'.NOMNOE', nuno2), nono2)
!
                    nomnoe(1)=nono2
                    coef(1)=-1.d0
!
                    do ino1 = 1, nno1
                        nuno1=zi(jconu+idecal-1+ino1)
                        coef1=zr(jcocf+idecal-1+ino1)
                        call jenuno(jexnum(mesh//'.NOMNOE', nuno1), nono1)
                        nomnoe(ino1+1)=nono1
                        coef(ino1+1)=coef1
!               SI LA RELATION EST UNE TAUTOLOGIE, ON NE L'ECRIT PAS :
                        if (nuno1 .eq. nuno2) then
                            if (abs(coef(ino1+1)-1.d0) .lt. 1.d-2) then
                                call utmess('A', 'CALCULEL5_49', sk=nono1)
                                goto 130
!
                            endif
                        endif
                    end do
!
!           -- AFFECTATION DES RELATIONS CONCERNANT LE NOEUD INO2 :
!           -----------------------------------------------------
                    if (dnor) then
                        do ino1 = 1, nno1+1
                            dim(ino1)=ndim
                            nomddl(ino1)='DEPL'
                            do idim = 1, ndim
                                direct(1+(ino1-1)*ndim1+idim-1)=zr(&
                                jnorm+ (vindire(ino2)-1)*ndim+&
                                idim-1)
                            end do
                        end do
                        call afrela(coef, [cbid], nomddl, nomnoe, dim,&
                                    direct, nno1+1, beta, betac, kbeta,&
                                    typcoe, fonree, typlag, 1.d-6, lisrel)
                    else
!
!               -- RELATIONS CONCERNANT LES TRANSLATIONS (DX/DY/DZ) :
!               -----------------------------------------------------
                        if (typrac .ne. 'MASSIF_COQUE') then
                            do k = 1, ndim
                                if (k .eq. 1) cmp='DX'
                                if (k .eq. 2) cmp='DY'
                                if (k .eq. 3) cmp='DZ'
                                do ino1 = 1, nno1+1
                                    nomddl(ino1)=cmp
                                end do
                                call afrela(coef, [cbid], nomddl, nomnoe, dim,&
                                            direct, nno1+1, beta, betac, kbeta,&
                                            typcoe, fonree, typlag, 1.d-6, lisrel)
                                call imprel(motfac, nno1+1, coef, nomddl, nomnoe,&
                                            beta)
                            end do
!
                        else if (typrac.eq.'MASSIF_COQUE') then
                            call jeveuo(mesh//'.COORDO    .VALE', 'L', jcoor)
                            call calir5(mesh, lisrel, nono2, nuno2, jcoor,&
                                        idecal, jconb, jcocf, jconu)
                        endif
!
!
!               -- RELATIONS CONCERNANT LES ROTATIONS (DRX/DRY/DRZ) :
!               -----------------------------------------------------
                        if (typrac .eq. 'COQUE') then
                            do k = 1, ndim
                                if (k .eq. 1) cmp='DRX'
                                if (k .eq. 2) cmp='DRY'
                                if (k .eq. 3) cmp='DRZ'
                                do ino1 = 1, nno1+1
                                    nomddl(ino1)=cmp
                                end do
                                call afrela(coef, [cbid], nomddl, nomnoe, dim,&
                                            direct, nno1+1, beta, betac, kbeta,&
                                            typcoe, fonree, typlag, 1.d-6, lisrel)
                                call imprel(motfac, nno1+1, coef, nomddl, nomnoe,&
                                            beta)
                            end do
!
                        else if (typrac.eq.'COQUE_MASSIF') then
                            call calir4(mesh, lisrel, nono2, ino2, zr(jlisv1+3*(ino2-1)),&
                                        jconb1, jcocf1, jconu1, ideca1, jconb2,&
                                        jcocf2, jconu2, ideca2)
                        endif
                    endif
130                 continue
                    idecal=idecal+nno1
                    if (typrac .eq. 'COQUE_MASSIF') then
                        ideca1=ideca1+zi(jconb1-1+ino2)
                        ideca2=ideca2+zi(jconb2-1+ino2)
                    endif
140                 continue
                end do
!
!
!       -- 3.1.2  S'IL Y A UNE ROTATION :
!       ---------------------------------
            else
                idecal=0
!
                do ino2 = 1, nbno2t
!
! ---       NNO1: NB DE NOEUD_MAIT LIES A INO2 :
!           ------------------------------------
                    nno1=zi(jconb-1+ino2)
                    if (nno1 .eq. 0) goto 260
                    do k = 1, idmax
                        nomnoe(k)=m8blan
                        nomddl(k)=m8blan
                        coef(k)=zero
                        dim(k)=0
                        do kk = 1, 3
                            direct(1+3*(k-1)+kk-1)=zero
                        end do
                    end do
!
                    normal(1)=zero
                    normal(2)=zero
                    normal(3)=zero
!
                    nuno2=ino2
                    call jenuno(jexnum(mesh//'.NOMNOE', nuno2), nono2)
!
                    if (dnor) then
                        ij=1
                    else
                        ij=ndim
                    endif
!
                    do ino1 = 1, nno1
                        nuno1=zi(jconu+idecal-1+ino1)
                        coef1=zr(jcocf+idecal-1+ino1)
                        call jenuno(jexnum(mesh//'.NOMNOE', nuno1), nono1)
                        nomnoe(1+ij+ino1-1)=nono1
                        coef(1+ij+ino1-1)=coef1
                    end do
!
!
!           -- AFFECTATION DES RELATIONS CONCERNANT LE NOEUD INO2 :
!           -----------------------------------------------------
                    if (dnor) then
                        do idim = 1, ndim
                            do jdim = 1, ndim
                                normal(idim)=normal(idim)+ mrota(jdim,&
                                idim)*zr(jnorm+(vindire(ino2)-1)*&
                                ndim+jdim-1)
                            end do
                        end do
                        coef(1)=1.0d0
                        nomnoe(1)=nono2
                        nomddl(1)='DEPL'
                        dim(1)=ndim
                        do idim = 1, ndim
                            direct(idim)=zr(jnorm+(vindire(1+&
                            ino2-1)-1)*ndim+ idim-1)
                        end do
                        do ino1 = 2, nno1+1
                            dim(ino1)=ndim
                            nomddl(ino1)='DEPL'
                            do idim = 1, ndim
                                direct(1+(ino1-1)*ndim1+idim-1)=-&
                                normal(idim)
                            end do
                        end do
                        call afrela(coef, [cbid], nomddl, nomnoe, dim,&
                                    direct, nno1+1, beta, betac, kbeta,&
                                    typcoe, fonree, typlag, 1.d-6, lisrel)
                    else
                        do k = 1, ndim
                            if (k .eq. 1) cmp='DX'
                            if (k .eq. 2) cmp='DY'
                            if (k .eq. 3) cmp='DZ'
                            do ino1 = 1, nno1
                                nomddl(1+ndim+ino1-1)=cmp
                            end do
                            do kk = 1, ndim
                                if (kk .eq. 1) cmp='DX'
                                if (kk .eq. 2) cmp='DY'
                                if (kk .eq. 3) cmp='DZ'
                                nomnoe(kk)=nono2
                                nomddl(kk)=cmp
                                coef(kk)=-mrota(kk,k)
                            end do
                            call afrela(coef, [cbid], nomddl, nomnoe, dim,&
                                        direct, nno1+ ndim, beta, betac, kbeta,&
                                        typcoe, fonree, typlag, 1.d-6, lisrel)
                            call imprel(motfac, nno1+ndim, coef, nomddl, nomnoe,&
                                        beta)
                        end do
                    endif
                    idecal=idecal+nno1
260                 continue
                end do
            endif
!
!
!       3.2 CAS "TEMP" :
!       =================
        else if (typlia.eq.'TEMP') then
            idecal=0
            do ino2 = 1, nbno2t
!           NNO1: NB DE NOEUD_MAIT LIES A INO2
                nno1=zi(jconb-1+ino2)
                if (nno1 .eq. 0) goto 300
!
                nuno2=ino2
                call jenuno(jexnum(mesh//'.NOMNOE', nuno2), nono2)
!
                nomnoe(1)=nono2
                coef(1)=-1.d0
!
                do ino1 = 1, nno1
                    nuno1=zi(jconu+idecal-1+ino1)
                    coef1=zr(jcocf+idecal-1+ino1)
                    call jenuno(jexnum(mesh//'.NOMNOE', nuno1), nono1)
                    nomnoe(ino1+1)=nono1
                    coef(ino1+1)=coef1
!             SI LA RELATION EST UNE TAUTOLOGIE, ON NE L'ECRIT PAS :
                    if (nuno1 .eq. nuno2) then
                        if (abs(coef(ino1+1)-1.d0) .lt. 1.d-2) then
                            call utmess('A', 'CALCULEL5_49', sk=nono1)
                            goto 290
!
                        endif
                    endif
                end do
!
!           -- AFFECTATION DE LA RELATION CONCERNANT LE NOEUD INO2 :
!           -----------------------------------------------------
                cmp='TEMP'
                do ino1 = 1, nno1+1
                    nomddl(ino1)=cmp
                end do
                call afrela(coef, [cbid], nomddl, nomnoe, dim,&
                            direct, nno1+1, beta, betac, kbeta,&
                            typcoe, fonree, typlag, 1.d-6, lisrel)
                call imprel(motfac, nno1+1, coef, nomddl, nomnoe,&
                            beta)
!
290             continue
                idecal=idecal+nno1
300             continue
            end do
        else
            ASSERT(.false.)
        endif
!
        call detrsd('CORRESP_2_MAILLA', corres)
        call detrsd('CORRESP_2_MAILLA', corre1)
        call detrsd('CORRESP_2_MAILLA', corre2)
        call jedetr(geom2)
        call jedetr('&&CALIRC.LIMANU1')
        call jedetr('&&CALIRC.LIMANU2')
        call jedetr('&&CALIRC.LINONU2')
        call jedetr('&&CALIRC.LISTK')
        call jedetr('&&CALIRC.LISV1')
        AS_DEALLOCATE(vi=vindire)
        call jedetr('&&NBNLMA.LN')
        call jedetr('&&NBNLMA.NBN')
        call jedetr('&&CANORT.NORMALE')
!
    end do
!
    AS_DEALLOCATE(vk8=nomnoe)
    AS_DEALLOCATE(vk8=nomddl)
    AS_DEALLOCATE(vr=coef)
    AS_DEALLOCATE(vr=direct)
    AS_DEALLOCATE(vi=dim)
    AS_DEALLOCATE(vi=elim)
!
! --- AFFECTATION DE LA LISTE DE RELATIONS A LA CHARGE :
!     ------------------------------------------------

    detr_lisrel = .true.
    liaison_epx = ' '
    if (phenom_ .eq. 'MECANIQUE') then
        call getvtx(' ', 'LIAISON_EPX', scal=liaison_epx, nbret=ibid)
        if (ibid.eq.1) then
            if (liaison_epx .eq. 'OUI') detr_lisrel = .false.
        endif
    endif
    
    call aflrch(lisrel, load, 'LIN', detr_lisrez=detr_lisrel)
!
! --- Copie des relations lineaires dans une table pour CALC_EUROPLEXUS
!
     if (liaison_epx .eq. 'OUI') call createTabRela(lisrel, load, motfac(1:16))
!
320 continue
    call jedema()
end subroutine
