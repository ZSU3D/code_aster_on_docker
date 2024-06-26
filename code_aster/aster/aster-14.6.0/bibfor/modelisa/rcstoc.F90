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

subroutine rcstoc(nommat, nomrc, noobrc, nbobj, valr, valc,&
                  valk, nbr, nbc, nbk)
! person_in_charge: mathieu.courtois@edf.fr
    implicit none
#include "jeveux.h"
#include "asterc/getmjm.h"
#include "asterfort/gettco.h"
#include "asterfort/assert.h"
#include "asterfort/create_enthalpy.h"
#include "asterfort/foverf.h"
#include "asterfort/fonbpa.h"
#include "asterfort/gcncon.h"
#include "asterfort/getvc8.h"
#include "asterfort/getvid.h"
#include "asterfort/getvr8.h"
#include "asterfort/getvtx.h"
#include "asterfort/jedema.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnum.h"
#include "asterfort/lxlgut.h"
#include "asterfort/tbexp2.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/indk16.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"

    integer :: nbr, nbc, nbk, nbobj
    real(kind=8) :: valr(*)
    complex(kind=8) :: valc(*)
    character(len=8) :: nommat
    character(len=19) :: noobrc
    character(len=16) :: valk(*)
    character(len=32) :: nomrc


! But: Stocker dans les 3 tableaux VALR, VALC et VALK les reels, les
!      complexes et les k16 caracterisant la loi de comportement de nom nomrc
!      Creer si necessaire (ORDRE_PARAM) les objets .ORDR et .KORD et les remplir
!
!  in  nommat : nom utilisateur du materiau
!  in  nomrc  : nom de la relation de comportement (mot cle facteur)
!  in  nbobj  : nombre de mcsimps
!  out valr   : vecteur des valeurs reelles
!  out valk   : vecteur des k16
!  out valc   : vecteur des complexes
!  out nbr    : nombre de reels
!  out nbc    : nombre de complexes
!  out nbk    : nombre de concepts (fonction, trc, table, liste)
!
! ----------------------------------------------------------------------
!
    real(kind=8) :: valr8, e1, ei, precma, valrr(4)
    character(len=16) :: valtx
    character(len=8) :: valch, nomcle(5)
    character(len=8) :: table, typfon, nompf(10)
    character(len=19) :: rdep, nomfct, nomint
    character(len=8) :: num_lisv
    character(len=16) :: nom_lisv
    character(len=24) :: valkk(2)
    character(len=16) :: typeco
    complex(kind=8) :: valc8
    integer ::   ibk, nbmax, vali, itrou, n1, posi, kr, kc, kf
    integer :: i, k, ii,  jrpv, jvale, nbcoup, n, jlisvr, jlisvf,nmcs
    integer :: iret, nbfct, nbpts, jprol, nbptm, nbpf
    integer :: dis_ecro_trac
    character(len=32), pointer :: nomobj(:) => null()
    character(len=8), pointer :: typobj(:) => null()
    character(len=24), pointer :: prol(:) => null()
    character(len=16), pointer :: ordr(:) => null()
    integer, pointer :: kord(:) => null()
    aster_logical :: lordre, lverif
! ----------------------------------------------------------------------
!
    call jemarq()
    AS_ALLOCATE(vk8=typobj, size=nbobj)
    AS_ALLOCATE(vk32=nomobj, size=nbobj)

    nbr = 0
    nbc = 0
    nbk = 0


!   -- 1. Recuperation de la liste des mots cles utilises
!         et de leurs types associes => nomobj(:) et typboj(:)
!   -------------------------------------------------------------------------
    call getmjm(nomrc, 1, nbobj, nomobj, typobj, nmcs)


!   -- 2. Le mot cle ORDRE_PARAM est special (mot cle cache).
!         Il donne l'ordre des mots cles simples pour l'acces via la routine rcvalt.F90.
!         On le scrute et on le recopie dans .ORDR et puis on le retire de la liste.
!   ------------------------------------------------------------------------------------
    itrou=0
    lordre=.false.
    do i = 1, nmcs
        if (nomobj(i).eq.'ORDRE_PARAM') then
            itrou=i
            lordre=.true.
            call getvtx(nomrc, 'ORDRE_PARAM', iocc=1, nbval=0, vect=ordr, nbret=n1)
            ASSERT(n1.lt.0)
            call wkvect(noobrc//'.ORDR', 'G V K16', -n1, vk16=ordr)
            call getvtx(nomrc, 'ORDRE_PARAM', iocc=1, nbval=-n1, vect=ordr, nbret=n1)
            ASSERT(n1.gt.0)
        endif
    enddo
    if (itrou.gt.0) then
        do i = 1, nmcs
            if (i.gt.itrou) then
                nomobj(i-1)=nomobj(i)
                typobj(i-1)=typobj(i)
            endif
        enddo
        nmcs=nmcs-1
    endif


!   -- 3. On verifie que les mots cles simples ont moins de 16 carateres
!   ---------------------------------------------------------------------
    do i = 1, nmcs
        ASSERT (nomobj(i).ne.' ')
        ASSERT (typobj(i).ne.' ')
        if (lxlgut(nomobj(i)) .gt. 16) then
            call utmess('F','MODELISA9_84', sk=nomobj(i))
        endif
    enddo


!   -- 4. On modifie typobj pour remplacer 'R8' par 'LR8',
!         'C8' par 'LC8' et 'CO' par 'LFO' quand ce sont des listes.
!   -------------------------------------------------------------------------
    do i = 1, nmcs
        if (typobj(i)(1:2) .eq. 'R8') then
            call getvr8(nomrc, nomobj(i), iocc=1, scal=valr8, nbret=n)
            if (n.lt.0) then
                typobj(i)='LR8'
            else
                ASSERT(n.eq.1)
            endif
        else if (typobj(i)(1:2) .eq. 'C8') then
            call getvc8(nomrc, nomobj(i), iocc=1, scal=valc8, nbret=n)
            if (n.lt.0) then
                typobj(i)='LC8'
            else
                ASSERT(n.eq.1)
            endif
        else if (typobj(i)(1:2) .eq. 'CO') then
            call getvid(nomrc, nomobj(i), iocc=1, scal=valch, nbret=n)
            call gettco(valch, typeco)
            if (typeco == ' ') then
                call utmess('F', 'FONCT0_71', sk=nomobj(i))
            endif
            if (typeco.eq.'TABLE_SDASTER') cycle
            lverif=(typeco(1:8).eq.'FONCTION' .or. &
                    typeco(1:5).eq.'NAPPE'    .or. &
                    typeco(1:7).eq.'FORMULE')
            ASSERT(lverif)
            if (n.lt.0) then
                typobj(i)='LFO'
            else
                ASSERT(n.eq.1)
            endif
        else if (typobj(i)(1:2) .eq. 'TX') then
            call getvtx(nomrc, nomobj(i), iocc=1, scal=valch, nbret=n)
            ASSERT(n.eq.1)
        else
            ASSERT(.false.)
        endif
    enddo


!   -- 5. Si le mot cle ORDRE_PARAM est fourni, on verifie que TOUS les mots cles fournis
!         font partie de la liste et on cree l'objet .KORD :
!            .KORD(1) : n1 : nombre total des mots cles MSIMP possibles de MFACT
!                            (=longueur de .ORDR)
!            .KORD(2) : nmcs : nombre de mots cles MSIMP rellement utilises
!            .KORD(2+i) : i   (pour i=1,nmcs)
!                 posi : indice du mot cles dans  .ORDR
!            .KORD(2+nmcs+i) : kr   (pour i=1,nmcs)
!                - si kr > 0 :  est l'indice du mot cle dans .VALR
!                - sinon : le mot cle n'est pas reel
!            .KORD(2+2*nmcs+i) : kc   (pour i=1,nmcs)
!                - si kc > 0 :  est l'indice du mot cle dans .VALC
!                - sinon : le mot cle n'est pas complexe
!            .KORD(2+3*nmcs+i) : kf   (pour i=1,nmcs)
!                - si kf > 0 :  est l'indice du mot cle dans .VALK(nmcs:)
!                - sinon : le mot cle n'est pas un concept (fonction, TRC, liste)
!
!   ------------------------------------------------------------------------------------------------
    if (lordre) then
        call wkvect(noobrc//'.KORD', 'G V I', 2+4*nmcs, vi=kord)
        kord(1)=n1
        kord(2)=nmcs

        kr=0
        kc=0
        kf=0
        do i = 1, nmcs
            posi = indk16(ordr,nomobj(i),1,n1)
            if (posi.eq.0) then
                valkk(1)=nomrc(1:24)
                valkk(2)=nomobj(i)(1:24)
                call utmess('F','MODELISA6_81',nk=2,valk=valkk)
            else
                kord(2+i)=posi
            endif
            if (typobj(i) .eq. 'R8') then
                kr=kr+1
                kord(2+nmcs+i)=kr
            else if (typobj(i) .eq. 'C8') then
                kc=kc+1
                kord(2+2*nmcs+i)=kc
            else
                kf=kf+1
                kord(2+3*nmcs+i)=kf
                ASSERT(typobj(i) .eq. 'CO')
            endif
        enddo
        ASSERT(kc.eq.0)
        ASSERT(kr+kf.eq.nmcs)
    endif


    ! --------------------------------------------------------------------
    !
    !   Glute : On traite les TX qu'on convertit en R8
    !       META_MECA* , BETON_DOUBLE_DP , RUPT_FRAG , CZM_LAB_MIX
    !       DIS_ECRO_TRAC, CABLE_GAINE
    ! --------------------------------------------------------------------
    dis_ecro_trac = 0
    if (nomrc(1:13).eq.'DIS_ECRO_TRAC') then
        dis_ecro_trac = 1
    endif
    do i = 1, nmcs
        if (typobj(i)(1:2) .eq. 'TX') then
            if (nomrc(1:9) .eq. 'ELAS_META') then
                call getvtx(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                if (n .eq. 1) then
                    if (nomobj(i) .eq. 'PHASE_REFE' .and. valtx .eq. 'CHAUD') then
                        nbr = nbr + 1
                        valr(nbr) = 1.d0
                        valk(nbr) = nomobj(i)(1:16)
                    else if( nomobj(i).eq.'PHASE_REFE' .and. valtx.eq.'FROID') then
                        nbr = nbr + 1
                        valr(nbr) = 0.d0
                        valk(nbr) = nomobj(i)(1:16)
                    endif
                endif
            else if (nomrc .eq. 'BETON_DOUBLE_DP') then
                call getvtx(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                if (n .eq. 1) then
                    if (nomobj(i) .eq. 'ECRO_COMP_P_PIC' .or. &
                        nomobj(i) .eq. 'ECRO_TRAC_P_PIC') then
                        nbr = nbr + 1
                        valk(nbr) = nomobj(i)(1:16)
                        if (valtx .eq. 'LINEAIRE') then
                            valr(nbr) = 0.d0
                        else
                            valr(nbr) = 1.d0
                        endif
                    endif
                endif
            else if ((nomrc(1:9).eq.'RUPT_FRAG') .or. (nomrc.eq.'CZM_LAB_MIX')) then
                call getvtx(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                if (n .eq. 1) then
                    if (nomobj(i) .eq. 'CINEMATIQUE') then
                        nbr = nbr + 1
                        valk(nbr) = nomobj(i)(1:16)
                        if (valtx .eq. 'UNILATER') then
                            valr(nbr) = 0.d0
                        else if (valtx.eq.'GLIS_1D') then
                            valr(nbr) = 1.d0
                        else if (valtx.eq.'GLIS_2D') then
                            valr(nbr) = 2.d0
                        else
                            ASSERT(.false.)
                        endif
                    else
                        ASSERT(.false.)
                    endif
                endif
            else if (nomrc(1:10).eq.'BETON_RAG') then
                call getvtx(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                if (n .eq. 1) then
                    if (nomobj(i) .eq. 'COMP_BETON') then
                        nbr = nbr + 1
                        valk(nbr) = 'TYPE_LOI'
                        if      (valtx.eq.'ENDO') then
                            valr(nbr) = 1.0D0
                        else if (valtx.eq.'ENDO_FLUA') then
                            valr(nbr) = 2.0D0
                        else if (valtx.eq.'ENDO_FLUA_RAG') then
                            valr(nbr) = 3.0D0
                        else
                            ASSERT(.false.)
                        endif
                    endif
                endif
            else if (nomrc(1:13).eq.'DIS_ECRO_TRAC') then
                dis_ecro_trac = 1
                call getvtx(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                if (n .eq. 1) then
                    if (nomobj(i) .eq. 'ECROUISSAGE') then
                        dis_ecro_trac = 2
                        nbr = nbr + 1
                        valk(nbr) = 'ECRO'
                        if      (valtx.eq.'ISOTROPE') then
                            valr(nbr) = 1.0D0
                        else if (valtx.eq.'CINEMATIQUE') then
                            valr(nbr) = 2.0D0
                        else
                            ASSERT(.false.)
                        endif
                    endif
                endif
            else if (nomrc(1:16).eq.'CABLE_GAINE_FROT') then
                call getvtx(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                if (n .eq. 1) then
                    if (nomobj(i) .eq. 'TYPE') then
                        nbr = nbr + 1
                        valk(nbr) = 'TYPE'
                        if      (valtx.eq.'FROTTANT') then
                            valr(nbr) = 1.0D0
                        else if (valtx.eq.'GLISSANT') then
                            valr(nbr) = 2.0D0
                        else if (valtx.eq.'ADHERENT') then
                            valr(nbr) = 3.0D0
                        else
                            ASSERT(.false.)
                        endif
                    endif
                endif
            endif
        endif
    enddo
!
!   Traitement de DIS_ECRO_TRAC / ECRO
!       ECRO est seulement présent quand FTAN existe, il peut donc être absent
!   dis_ecro_trac = 0 : Le comportement n'existe pas. Il n'y a rien à faire.
!   dis_ecro_trac = 2 : Tout est bon ECRO a été traité. Il n'y a rien de plus à faire.
!   dis_ecro_trac = 1 : Le comportement existe, et ECRO n'existe pas ==> on crée la variable.
    if ( dis_ecro_trac == 1 ) then
        nbr = nbr + 1
        valk(nbr) = 'ECRO'
        valr(nbr) = 0.0D0
    endif

!   -- 7. Stockage des informations dans VALK, VALR et VALC :
!   ---------------------------------------------------------

!   -- 7.1 on traite les reels
!   --------------------------
    do i = 1, nmcs
        if (typobj(i)(1:3) .eq. 'R8 ') then
            call getvr8(nomrc, nomobj(i), iocc=1, scal=valr8, nbret=n)
            ASSERT(n.eq.1)
            nbr = nbr + 1
            valr(nbr) = valr8
            valk(nbr) = nomobj(i)(1:16)
        endif
    enddo

!   -- 7.2 on traite les complexes
!   ------------------------------
    do i = 1, nmcs
        if (typobj(i)(1:3) .eq. 'C8 ') then
            call getvc8(nomrc, nomobj(i), iocc=1, scal=valc8, nbret=n)
            ASSERT(n.eq.1)
            nbc = nbc + 1
            valc(nbr+nbc) = valc8
            valk(nbr+nbc) = nomobj(i)(1:16)
        endif
    enddo

!   -- 3.3 on traite ensuite les concepts CO puis les listes (LR8/LC8/LFO):
!   ------------------------------------------------------------------------

!   -- 7.3.1 : on stocke le nom des parametres concernes :
    do i = 1, nmcs
        if (typobj(i)(1:3) .eq. 'CO ') then
            call getvid(nomrc, nomobj(i), iocc=1, scal=valch, nbret=n)
            if (n .eq. 1) then
                nbk = nbk + 1
                valk(nbr+nbc+nbk) = nomobj(i)(1:16)
            else
                ASSERT(.false.)
                ASSERT(n.eq.0)
            endif
        endif
    enddo

    do i = 1, nmcs
        if ((typobj(i).eq.'LR8') .or. (typobj(i).eq.'LC8') .or. (typobj(i).eq.'LFO')) then
            nbk = nbk + 1
            valk(nbr+nbc+nbk) = nomobj(i)(1:16)
        endif
    enddo

!   -- 7.3.2 : on stocke le nom des structures de donnees : fonctions, TRC, listes
    ibk = 0
    do i = 1, nmcs
        if (typobj(i)(1:3) .eq. 'CO ') then
            call getvid(nomrc, nomobj(i), iocc=1, scal=valch, nbret=n)
            if (n .eq. 1) then
                ibk = ibk + 1
                valk(nbr+nbc+nbk+ibk) = valch
            else
                ASSERT(n.eq.0)
            endif
        endif
    enddo

    do i = 1, nmcs
        if ((typobj(i).eq.'LR8') .or. (typobj(i).eq.'LC8') .or. (typobj(i).eq.'LFO')) then
            call gcncon('.', num_lisv)
            nom_lisv=nommat//num_lisv
            if (typobj(i) .eq. 'LR8') then
                call getvr8(nomrc, nomobj(i), iocc=1, scal=valr8, nbret=n)
                ASSERT(n.lt.0)
                n=-n
                call wkvect(nom_lisv//'.LISV_R8','G V R',n,jlisvr)
                call getvr8(nomrc, nomobj(i), iocc=1, nbval=n, vect=zr(jlisvr))
            else if (typobj(i) .eq. 'LC8') then
                ASSERT(.false.)
            else if (typobj(i) .eq. 'LFO') then
                call getvid(nomrc, nomobj(i), iocc=1, scal=valtx, nbret=n)
                ASSERT(n.lt.0)
                n=-n
                call wkvect(nom_lisv//'.LISV_FO','G V K8',n,jlisvf)
                call getvid(nomrc, nomobj(i), iocc=1, nbval=n, vect=zk8(jlisvf))
            endif
            ibk = ibk + 1
            valk(nbr+nbc+nbk+ibk) = nom_lisv
        endif
    enddo


!   -- 7. creation d'une fonction pour stocker r(p) :
!   -------------------------------------------------
    if (( nomrc(1:8) .eq. 'TRACTION' ) .or. ( nomrc(1:13) .eq. 'META_TRACTION' )) then
        if (nomrc(1:8) .eq. 'TRACTION') then
            nomcle(1)(1:4)='SIGM'
        endif
        if (nomrc(1:13) .eq. 'META_TRACTION') then
            nomcle(1)(1:7)='SIGM_F1'
            nomcle(2)(1:7)='SIGM_F2'
            nomcle(3)(1:7)='SIGM_F3'
            nomcle(4)(1:7)='SIGM_F4'
            nomcle(5)(1:7)='SIGM_C '
        endif
        nbmax = 0
        do ii = 1, nbk
            do i = 1, nbk
                if ((valk(nbr+nbc+ii)(1:6) .eq. 'SIGM  ') .or.&
                    (valk(nbr+nbc+ii)(1:7) .eq. 'SIGM_F1') .or.&
                    (valk(nbr+nbc+ii)(1:7) .eq. 'SIGM_F2') .or.&
                    (valk(nbr+nbc+ii)(1:7) .eq. 'SIGM_F3') .or.&
                    (valk(nbr+nbc+ii)(1:7) .eq. 'SIGM_F4') .or.&
                    (valk(nbr+nbc+ii)(1:7) .eq. 'SIGM_C ')) then
                    goto 151
                endif
            enddo
            call utmess('F', 'MODELISA6_70', sk=nomcle(ii))
151         continue
            nomfct = valk(nbr+nbc+nbk+ii)
!
            call jeveuo(nomfct//'.PROL', 'L', vk24=prol)
            if (prol(1)(1:1) .eq. 'F') then
                call jelira(nomfct//'.VALE', 'LONMAX', nbptm)
                if (nomrc(1:8) .eq. 'TRACTION') then
                    if (nbptm .lt. 4) then
                        call utmess('F', 'MODELISA6_71', sk=nomcle(ii))
                    endif
                endif
                if (nomrc(1:13) .eq. 'META_TRACTION') then
                    if (nbptm .lt. 2) then
                        call utmess('F', 'MODELISA6_72', sk=nomcle(ii))
                    endif
                endif
                nbcoup = nbptm / 2
                if (nbptm .ge. nbmax) nbmax = nbptm
!
                call jeveuo(nomfct//'.VALE', 'L', jrpv)
                if (zr(jrpv) .le. 0.d0) then
                    valkk (1) = nomcle(ii)
                    valkk (2) = nomfct
                    valrr (1) = zr(jrpv)
                    call utmess('F', 'MODELISA9_59', nk=2, valk=valkk, sr=valrr(1))
                endif
                if (zr(jrpv+nbptm/2) .le. 0.d0) then
                    valkk (1) = nomcle(ii)
                    valkk (2) = nomfct
                    valrr (1) = zr(jrpv+nbptm/2)
                    call utmess('F', 'MODELISA9_60', nk=2, valk=valkk, sr=valrr(1))
                endif
!               VERIF ABSCISSES CROISSANTES (AU SENS LARGE)
                iret=2
                call foverf(zr(jrpv), nbcoup, iret)
                iret = 0
                e1 = zr(jrpv+nbcoup) / zr(jrpv)
                precma = 1.d-10
!
                do i = 1, nbcoup-1
                    ei = (zr(jrpv+nbcoup+i) - zr(jrpv+nbcoup+i-1))/(zr(jrpv+i) - zr(jrpv+i-1))
                    if (ei .gt. e1) then
                        iret = iret + 1
                        valkk (1) = nomcle(ii)
                        valrr (1) = e1
                        valrr (2) = ei
                        valrr (3) = zr(jrpv+i)
                        call utmess('E', 'MODELISA9_61', sk=valkk(1), nr=3, valr=valrr)
                    else if ((e1-ei)/e1 .le. precma) then
                        valkk (1) = nomcle(ii)
                        valrr (1) = e1
                        valrr (2) = ei
                        valrr (3) = precma
                        valrr (4) = zr(jrpv+i)
                        call utmess('A', 'MODELISA9_62', sk=valkk(1), nr=4, valr=valrr)
                    endif
                enddo
                if (iret .ne. 0) then
                    call utmess('F', 'MODELISA6_73')
                endif
!
            else if (prol(1)(1:1) .eq. 'N') then
                call jelira(nomfct//'.VALE', 'NUTIOC', nbfct)
                nbptm = 0
                do k = 1, nbfct
                    call jelira(jexnum(nomfct//'.VALE', k), 'LONMAX', nbpts)
                    nbcoup = nbpts / 2
                    if (nbpts .ge. nbmax) nbmax = nbpts
                    if (nomrc(1:8) .eq. 'TRACTION') then
                        if (nbpts .lt. 4) then
                            call utmess('F', 'MODELISA6_74')
                        endif
                    endif
                    if (nomrc(1:13) .eq. 'META_TRACTION') then
                        if (nbpts .lt. 2) then
                            call utmess('F', 'MODELISA6_75', sk=nomcle( ii))
                        endif
                    endif
                    call jeveuo(jexnum(nomfct//'.VALE', k), 'L', jrpv)
                    if (zr(jrpv) .le. 0.d0) then
                        vali = k
                        valkk (1) = nomcle(ii)
                        valkk (2) = nomfct
                        valrr (1) = zr(jrpv)
                        call utmess('F', 'MODELISA9_63', nk=2, valk=valkk, si=vali, sr=valrr(1))
                    endif
                    if (zr(jrpv+nbpts/2) .le. 0.d0) then
                        vali = k
                        valkk (1) = nomcle(ii)
                        valkk (2) = nomfct
                        valrr (1) = zr(jrpv+nbpts/2)
                        call utmess('F', 'MODELISA9_64', nk=2, valk=valkk, si=vali, sr=valrr(1))
                    endif

!                   verif abscisses croissantes (au sens large)
                    iret=2
                    call foverf(zr(jrpv), nbcoup, iret)
                    iret = 0
                    e1 = zr(jrpv+nbcoup) / zr(jrpv)
                    do i = 1, nbcoup-1
                        ei = (zr(jrpv+nbcoup+i) - zr(jrpv+nbcoup+i-1))/(zr(jrpv+i) - zr(jrpv+i-1))
                        if (ei .gt. e1) then
                            iret = iret + 1
                            valkk (1) = nomcle(ii)
                            valrr (1) = e1
                            valrr (2) = ei
                            valrr (3) = zr(jrpv+i)
                            call utmess('E', 'MODELISA9_65', sk=valkk(1), nr=3, valr=valrr)
                        endif
                    enddo
                    if (iret .ne. 0) then
                        call utmess('F', 'MODELISA6_73')
                    endif
                enddo
!
            else
                call utmess('F', 'MODELISA6_76')
            endif
        enddo
!
        rdep = nommat//'.&&RDEP'
        call wkvect(rdep//'.PROL', 'G V K24', 6, jprol)
        zk24(jprol ) = 'FONCTION'
        zk24(jprol+1) = 'LIN LIN '
        zk24(jprol+2) = 'EPSI    '
        zk24(jprol+3) = prol(4)
        call wkvect(rdep//'.VALE', 'G V R', 2*nbmax, jvale)
    endif


!   -- 8. Creation si necessaire d'une fonction pour stocker beta
!         (enthalpie volumique) calculee a partir de RHO_CP
!   ---------------------------------------------------------------
    if (nomrc(1:8) .eq. 'THER_NL') then
        do i = 1, nbk
            if (( valk(nbr+nbc+i)(1:4) .eq. 'BETA' )) then
                nomfct = valk(nbr+nbc+nbk+i)
!               -- il n'y a rien a faire, on travaille directement avec beta
                goto 651
            endif
        enddo
        do i = 1, nbk
            if (( valk(nbr+nbc+i)(1:6) .eq. 'RHO_CP' )) then
                nomfct = valk(nbr+nbc+nbk+i)
                goto 661
            endif
        enddo
        goto 651
661     continue

        call gcncon('_', nomint)
        call create_enthalpy(nomfct, nomint)

        do i = nbk, 1, -1
            valk(nbr+nbc+nbk+i+1) = valk(nbr+nbc+nbk+i)
        enddo
        nbk = nbk + 1
        valk(nbr+nbc+ nbk) = 'BETA    '
        valk(nbr+nbc+2*nbk) = nomint(1:16)
651     continue
    endif


!   -- 9. Verification des noms des parametres des tables TRC :
!   -----------------------------------------------------------
    if (nomrc(1:10) .eq. 'META_ACIER') then
        do i = 1, nbk
            if (valk(nbr+nbc+i)(1:3) .eq. 'TRC') then
                call getvid(nomrc, 'TRC', iocc=1, scal=table, nbret=n)
                call tbexp2(table, 'VITESSE')
                call tbexp2(table, 'PARA_EQ')
                call tbexp2(table, 'COEF_0')
                call tbexp2(table, 'COEF_1')
                call tbexp2(table, 'COEF_2')
                call tbexp2(table, 'COEF_3')
                call tbexp2(table, 'COEF_4')
                call tbexp2(table, 'COEF_5')
                call tbexp2(table, 'NB_POINT')
                call tbexp2(table, 'Z1')
                call tbexp2(table, 'Z2')
                call tbexp2(table, 'Z3')
                call tbexp2(table, 'TEMP')
                call tbexp2(table, 'SEUIL')
                call tbexp2(table, 'AKM')
                call tbexp2(table, 'BKM')
                call tbexp2(table, 'TPLM')
                call tbexp2(table, 'DREF')
                call tbexp2(table, 'A')
            endif
        enddo
    endif


!   -- 10. Verification que RHO ne peut etre une fonction que de la geometrie :
!   ---------------------------------------------------------------------------
    if (nomrc .eq. 'ELAS_FO') then
        call getvid(nomrc, 'RHO', iocc=1, scal=nomfct, nbret=n)
        if (n.eq.1) then
            call jeveuo(nomfct//'.PROL', 'L', vk24=prol)
            call fonbpa(nomfct, prol, typfon, 10, nbpf, nompf)
            do i = 1, nbpf
                if (nompf(i).ne.'X' .and. nompf(i).ne.'Y' .and. nompf(i).ne.'Z') then
                    valkk(1)=nomfct
                    valkk(2)=nompf(i)
                    call utmess('F', 'MODELISA6_92', nk=2, valk=valkk)
                endif
            enddo
        endif
    endif

    AS_DEALLOCATE(vk8=typobj)
    AS_DEALLOCATE(vk32=nomobj)

    call jedema()
end subroutine
