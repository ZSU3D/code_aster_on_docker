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

subroutine cteltb(nbma, mesmai, noma, nbval, nkcha,&
                  nkcmp, nkvari, toucmp, nbcmp, typac, ndim,&
                  nrval, resu, nomtb, nsymb, chpgs, &
                  tych, nival, niord)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
!
#include "asterc/indik8.h"
#include "asterfort/assert.h"
#include "asterfort/carces.h"
#include "asterfort/celces.h"
#include "asterfort/cesexi.h"
#include "asterfort/indiis.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jelira.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexatr.h"
#include "asterfort/jexnum.h"
#include "asterfort/tbajli.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
!
    integer :: nbcmp, ndim, nbval, nbma
    character(len=4) :: tych
    character(len=8) :: typac, noma, resu, nomtb
    character(len=16) :: nsymb
    character(len=19) :: chpgs
    character(len=24) :: nkcha, nkcmp, nkvari, mesmai, nival, nrval, niord
    aster_logical :: toucmp
!     ----- OPERATEUR CREA_TABLE , MOT-CLE FACTEUR RESU   --------------
!
!        BUT : REMPLISSAGE DE LA TABLE POUR UN CHAM_ELEM OU UNE CARTE
!
!        IN     : NKCHA (K24)  : OBJET DES NOMS DE CHAMP
!                 RESU  (K8)   : NOM DU RESULTAT (SI RESULTAT,SINON ' ')
!                 NKCMP  (K24) : OBJET DES NOMS DE COMPOSANTES  (NOM_CMP)
!                 NKVARI (K24) : OBJET DES NOMS DE VAR. INTERNES (NOM_VARI)
!                 TOUCMP (L)   : INDIQUE SI TOUT_CMP EST RENSEIGNE
!                 NBCMP (I)    : NOMBRE DE COMPOSANTES LORSQUE
!                                NOM_CMP EST RENSEIGNE, 0 SINON
!                 TYPAC (K8)   : ACCES (ORDRE,MODE,FREQ,INST)
!                 NBVAL (I)    : NOMBRE DE VALEURS D'ACCES
!                 NOMA   (K8)  : NOM DU MAILLAGE
!                 MESMAI (K24) : OBJET DES NOMS DE MAILLE
!                 NRVAL (K16)  : OBJET DES VALEURS D'ACCES (REELS)
!                 NIVAL (K16)  : OBJET DES VALEURS D'ACCES (ENTIERS)
!                 NIORD (K16)  : NOM D'OBJET DES NUMEROS D'ORDRE
!                 NSYMB (K16)  : NOM SYMBOLIQUE DU CHAMP
!                 TYCH  (K4)   : TYPE DE CHAMP (ELNO,ELEM,ELGA,CART)
!                 CHPGS (K19)  : CHAMP DES COORD DES POINTS DE GAUSS
!                 NBMA  (I)    : NOMBRE DE MAILLES UTILISATEUR
!
!        IN/OUT : NOMTB (K24)  : OBJET TABLE
!
! ----------------------------------------------------------------------
!
    integer :: jcmp, jkcha, jlma, jrval, jival, jniord, jconx2
    integer :: jcpgaussl, jcpgaussd
    integer :: i, j, jcesl, jcesd, nbmax
    integer :: nbcmpx
    integer :: n, ima, ipt, ispt, icmp, indma, nbpt, kk
    integer :: nbcmpt, nbspt, inot, kcp, indcmp, iad, ni, nk, nr
    integer :: nbpara, iret, jvari, iexi, nbvari, nbspt_coord
    character(len=8) :: kma, kno
    complex(kind=8) :: cbid
    character(len=19) :: chames
    character(len=16), pointer :: nom_cmp(:) => null()
    character(len=16), pointer :: table_parak(:) => null()
    integer, pointer :: table_vali(:) => null()
    character(len=16), pointer :: table_valk(:) => null()
    real(kind=8), pointer :: table_valr(:) => null()
    real(kind=8), pointer :: val_cmp(:) => null()
    character(len=8), pointer :: cesc(:) => null()
    real(kind=8), pointer :: cesv(:) => null()
    real(kind=8), pointer :: vcpgaussv(:) => null()
    integer, pointer :: connex(:) => null()
    real(kind=8), pointer :: vale(:) => null()
    logical :: au_sous_point
!
!
    call jemarq()
!
!   INITIALISATIONS
    cbid=(0.d0,0.d0)
    chames = '&&CTELTB.CES       '
    call jeveuo(nkcmp, 'L', jcmp)
    call jeexin(nkvari, iexi)
    if (iexi.gt.0) then
        call jeveuo(nkvari, 'L', jvari)
        call jelira(nkvari, 'LONMAX', nbvari)
        ASSERT(nbvari.eq.nbcmp)
        ASSERT(.not.toucmp)
    else
        jvari=0
        nbvari=0
    endif
    call jeveuo(nkcha, 'L', jkcha)
    call jeveuo(mesmai, 'L', jlma)
    call jeveuo(nrval, 'L', jrval)
    call jeveuo(nival, 'L', jival)
    call jeveuo(niord, 'L', jniord)
    call jeveuo(noma//'.COORDO    .VALE', 'L', vr=vale)
    call jeveuo(noma//'.CONNEX', 'L', vi=connex)
    call jeveuo(jexatr(noma//'.CONNEX', 'LONCUM'), 'L', jconx2)
!
    au_sous_point = .true.
    if (tych .eq. 'ELGA') then
        call jeveuo(chpgs//'.CESV', 'L', vr=vcpgaussv)
        call jeveuo(chpgs//'.CESL', 'L',    jcpgaussl)
        call jeveuo(chpgs//'.CESD', 'L',    jcpgaussd)
    endif
!
!   TABLEAU D'ENTIERS DE LA TABLE: ZI(JI)
!   TABLEAU DE REELS DE LA TABLE: ZR(JR)
!   TABLEAU DE CARACTERES DE LA TABLE: ZK16(JK)
!   POUR DES RAISONS DE PERF, CES TABLEAUX ONT ETE SORTIS DE
!   LA BOUCLE, D'OU DES DIMENSIONS EN DUR (NOMBRE SUFFISANT)
    AS_ALLOCATE(vr=table_valr, size=250)
    AS_ALLOCATE(vi=table_vali, size=250)
    AS_ALLOCATE(vk16=table_valk, size=250)
!
!   LECTURE DES CHAMPS ET REMPLISSAGE DE LA TABLE
    do i = 1, nbval
        if (zk24(jkcha+i-1)(1:18) .ne. '&&CHAMP_INEXISTANT') then
!           PASSAGE CHAMP => CHAM_ELEM_S
            if (tych(1:2) .eq. 'EL') then
                call celces(zk24(jkcha+i-1), 'V', chames)
            else if (tych.eq.'CART') then
                call carces(zk24(jkcha+i-1), 'ELEM', ' ', 'V', chames, ' ', iret)
                ASSERT(iret.eq.0)
            else
                ASSERT(.false.)
            endif
            call jeveuo(chames//'.CESV', 'L', vr=cesv)
            call jeveuo(chames//'.CESL', 'L', jcesl)
            call jeveuo(chames//'.CESD', 'L', jcesd)
            call jeveuo(chames//'.CESC', 'L', vk8=cesc)
!
!           NOMBRE DE MAILLES MAX DU CHAMP : NBMAX
            nbmax=zi(jcesd)
!           NOMBRE DE COMPOSANTES MAX DU CHAMP : NBCMPX
            nbcmpx=zi(jcesd+1)
!           NOMBRE DE COMPOSANTES DESIREES : N
            if (toucmp) then
                n=nbcmpx
            else
                n=nbcmp
            endif
!           TABLEAU DES VALEURS DES COMPOSANTES DESIREES: ZR(JVAL)
            AS_ALLOCATE(vr=val_cmp, size=n)
!           TABLEAU DES NOMS DE COMPOSANTES DESIREES : ZK8(JKVAL)
            AS_ALLOCATE(vk16=nom_cmp, size=n)
!           ON PARCOURT LES MAILLES
            cyima: do ima = 1, nbmax
!               SI LA MAILLE FAIT PARTIE DES MAILLES DESIREES,
!               ON POURSUIT, SINON ON VA A LA MAILLE SUIVANTE:
                indma=indiis(zi(jlma),ima,1,nbma)
                if (indma .eq. 0) cycle cyima
!               NOMBRE DE POINTS DE LA MAILLE IMA : NBPT
                nbpt=zi(jcesd+5+4*(ima-1))
!               Nombre de composantes portees par les points de la maille ima
                nbcmpt=zi(jcesd+5+4*(ima-1)+2)
!               Nombre de sous-points portes par les points de la maille ima
                nbspt=zi(jcesd+5+4*(ima-1)+1)
                if (tych .eq. 'ELGA') then
                    nbspt_coord=zi(jcpgaussd+5+4*(ima-1)+1)
                    if ( nbspt .ne. nbspt_coord ) then
                        call utmess('A', 'CALCULEL2_52',ni=2,vali=[nbspt,nbspt_coord])
                    endif
                endif
!
!               ON PARCOURT LES POINTS DE LA MAILLE IMA
                do ipt = 1, nbpt
!                   NUMERO DU POINT (DU MAILLAGE GLOBAL): INOT
                    inot = connex(zi(jconx2-1+ima)+ipt-1)
!                   ON PARCOURT LES SOUS-POINTS DE LA MAILLE IMA
                    cyispt: do ispt = 1, nbspt
                        kcp=0
!                       ON PARCOURT LES COMPOSANTES PORTEES PAR LE POINT IPT
                        cyicmp: do icmp = 1, nbcmpt
                            if (.not.toucmp) then
                                indcmp=indik8(zk8(jcmp),cesc(icmp), 1,nbcmp)
!                               si la composante fait partie des composantes desirees,
!                               on poursuit, sinon on va a la composante suivante
                                if (indcmp .eq. 0) cycle cyicmp
                            endif
!                           Valeur de icmp au point ipt de la maille ima: zr(jcesv+iad-1)
                            call cesexi('C', jcesd, jcesl, ima, ipt, ispt, icmp, iad)
                            if (iad .gt. 0) then
                                kcp=kcp+1
                                val_cmp(kcp)=cesv(iad)
                                if (jvari.eq.0) then
                                    nom_cmp(kcp)=cesc(icmp)
                                else
                                    ASSERT(.not.toucmp)
                                    ASSERT(indcmp.gt.0 .and. indcmp.le.nbvari)
                                    nom_cmp(kcp)=zk16(jvari-1+indcmp)
                                endif
                            endif
                        enddo cyicmp
!
                        if (kcp .eq. 0) cycle cyispt
!                       POUR NE PAS DEBORDER DES OBJETS (L=250):
                        ASSERT(kcp.le.200)
!
!                       SOIT NI LE NOMBRE DE ENTIERS DE LA TABLE
!                       SOIT NR LE NOMBRE DE REELS DE LA TABLE
!                       SOIT NK LE NOMBRE DE CARACTERES DE LA TABLE
                        ni=1
                        nk=3
                        nr=kcp
                        if ( (tych.eq.'ELNO').or.(tych.eq.'ELGA') ) then
                            nr = nr + ndim
                        endif
!
                        if (resu .ne. ' ') then
                            if (typac .eq. 'FREQ' .or. typac .eq. 'INST') then
                                nr = nr + 1
                            else if (typac.eq.'MODE') then
                                ni = ni + 1
                            endif
                        else
                            ni=0
                            nk=2
                        endif
!
                        if (tych .eq. 'ELNO') then
!                           noeud + sous_point
                            nk=nk+1
                            ni=ni+1
                        else if (tych.eq.'ELGA') then
!                           point + sous_point
                            ni=ni+2
                        else if (tych.eq.'ELEM') then
!                           sous_point
                            ni=ni+1
                        endif
!
!                       ON REMPLIT LES TABLEAUX ZI(JI),ZR(JR),ZK16(JK)
                        kk=0
                        if (typac .eq. 'FREQ' .or. typac .eq. 'INST') then
                            table_valr(kk+1)=zr(jrval+i-1)
                            kk=kk+1
                        endif
                        if (tych .eq. 'ELNO') then
                            do j = 1, ndim
                                table_valr(kk+1)=vale(1+3*(inot-1)+j-1)
                                kk=kk+1
                            enddo
                        else if (tych.eq.'ELGA') then
                            do j = 1, ndim
                                call cesexi('C', jcpgaussd, jcpgaussl, ima, ipt, ispt, j, iad)
                                if (iad .gt. 0) then
                                    table_valr(kk+1)=vcpgaussv(iad)
                                    kk=kk+1
                                endif
                            enddo
                        endif
                        do j = 1, kcp
                            table_valr(kk+1)=val_cmp(j)
                            kk=kk+1
                        enddo
                        ASSERT(kk .eq. nr)
!
                        kk=0
                        if (resu .ne. ' ') then
                            table_vali(kk+1)=zi(jniord+i-1)
                            kk=kk+1
                        endif
                        if (typac .eq. 'MODE') then
                            table_vali(kk+1)=zi(jival+i-1)
                            kk=kk+1
                        endif
                        if (tych .eq. 'ELGA') then
                            table_vali(kk+1)=ipt
                            kk=kk+1
                        endif
                        if (tych(1:2) .eq. 'EL') then
                            table_vali(kk+1)=ispt
                            kk=kk+1
                        endif
                        ASSERT(kk .eq. ni)
!
                        kk=0
                        if (resu .eq. ' ') then
                            table_valk(kk+1)=zk24(jkcha+i-1)(1:16)
                            kk=kk+1
                        else
                            table_valk(kk+1)=resu
                            kk=kk+1
                            table_valk(kk+1)=nsymb
                            kk=kk+1
                        endif
                        call jenuno(jexnum(noma//'.NOMMAI', ima), kma)
                        table_valk(kk+1)=kma
                        kk=kk+1
                        if (tych .eq. 'ELNO') then
                            call jenuno(jexnum(noma//'.NOMNOE', inot), kno)
                            table_valk(kk+1)=kno
                            kk=kk+1
                        endif
                        ASSERT(kk .eq. nk)
!
!                       TABLEAU DES NOMS DE PARAMETRES DE LA TABLE
                        nbpara=nr+ni+nk
                        AS_ALLOCATE(vk16=table_parak, size=nbpara)
!
                        kk=0
                        if (resu .eq. ' ') then
                            table_parak(kk+1)='CHAM_GD'
                            kk=kk+1
                        else
                            table_parak(kk+1)='RESULTAT'
                            kk=kk+1
                            table_parak(kk+1)='NOM_CHAM'
                            kk=kk+1
                        endif
!
                        if (resu .ne. ' ') then
                            if (typac .ne. 'ORDRE') then
                                table_parak(kk+1)=typac
                                kk=kk+1
                            endif
                            table_parak(kk+1)='NUME_ORDRE'
                            kk=kk+1
                        endif
                        table_parak(kk+1)='MAILLE'
                        kk=kk+1
                        if (tych .eq. 'ELNO') then
                            table_parak(kk+1)='NOEUD'
                            kk=kk+1
                        else if (tych.eq.'ELGA') then
                            table_parak(kk+1)='POINT'
                            kk=kk+1
                        endif
                        if (tych(1:2) .eq. 'EL') then
                            table_parak(kk+1)='SOUS_POINT'
                            kk=kk+1
                        endif
!
!                       COORDONNEES
                        if (tych .eq. 'ELNO' .or. tych .eq. 'ELGA') then
                            table_parak(kk+1)='COOR_X'
                            kk=kk+1
                            if (ndim .ge. 2) then
                                table_parak(kk+1)='COOR_Y'
                                kk=kk+1
                            endif
                            if (ndim .eq. 3) then
                                table_parak(kk+1)='COOR_Z'
                                kk=kk+1
                            endif
                        endif
!
!                       COMPOSANTES :
                        do j = 1, kcp
                            table_parak(kk+1)=nom_cmp(j)
                            kk=kk+1
                        enddo
!
                        ASSERT(kk .le. nbpara)
!                       ON AJOUTE LA LIGNE A LA TABLE
                        call tbajli(nomtb, nbpara, table_parak, table_vali, table_valr,&
                                    [cbid], table_valk, 0)
!
                        AS_DEALLOCATE(vk16=table_parak)
                    enddo cyispt
                enddo
            enddo cyima
            AS_DEALLOCATE(vk16=nom_cmp)
            AS_DEALLOCATE(vr=val_cmp)
!
        endif
!
    enddo
!
    AS_DEALLOCATE(vr=table_valr)
    AS_DEALLOCATE(vi=table_vali)
    AS_DEALLOCATE(vk16=table_valk)
!
    call jedema()
!
end subroutine
