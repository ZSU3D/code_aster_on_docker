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

subroutine iremed(nomcon, ifichi, nocham, novcmp, partie,&
                  liordr, lresu, nbnoec, linoec, nbmaec,&
                  limaec, nomcmp, lvarie, carael, linopa)
    implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/carces.h"
#include "asterfort/celces.h"
#include "asterfort/codent.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/exisd.h"
#include "asterfort/irchme.h"
#include "asterfort/irmpar.h"
#include "asterfort/jedema.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/mdnoch.h"
#include "asterfort/rsexch.h"
#include "asterfort/rsutrg.h"
#include "asterfort/utcmp3.h"
#include "asterfort/utmess.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
#include "asterfort/bool_to_int.h"
!
    character(len=8) :: carael
    character(len=19) :: linopa
    character(len=*) :: nomcon, novcmp, nocham, liordr, nomcmp, partie
    integer :: ifichi, nbnoec, linoec(*), nbmaec, limaec(*)
    aster_logical :: lresu, lvarie
! person_in_charge: nicolas.sellenet at edf.fr
!
!-----------------------------------------------------------------------
!     ECRITURE D'UN CONCEPT SUR FICHIER MED
!
! IN  NOMCON : K8  : NOM DU CONCEPT A IMPRIMER
! IN  IFICHI : IS  : UNITE LOGIQUE D'ECRITURE
! IN  NOCHAM : K*  : NOM DES CHAMPS A IMPRIMER ( EX 'DEPL', .... )
! IN  NOVCMP : K*  : NOM JEVEUX DE L'OBJET CONTENANT LES NOMS MED
! IN  PARTIE : K4  : IMPRESSION DE LA PARTIE COMPLEXE OU REELLE DU CHAMP
! IN  LIORDR : K*  : LISTE DES NUMEROS D'ORDRE A IMPRIMER
! IN  LRESU  : L   : INDIQUE SI NOMCON EST UN CHAMP OU UN RESULTAT
! IN  NBNOEC : I   : NOMBRE DE NOEUDS A IMPRIMER
! IN  LINOEC : I   : NUMEROS DES NOEUDS A IMPRIMER
! IN  NBMAEC : I   : NOMBRE DE MAILLES A IMPRIMER
! IN  LIMAEC : I   : NUMEROS DES MAILLES A IMPRIMER
! IN  NOMCMP : K*  : NOMS DES COMPOSANTES A IMPRIMER
! IN  CARAEL : K*  : NOM DU CARA_ELEM
! IN  NOPARA : K16 : NOM D'UN PARAMATRE A AJOUTER
!     ------------------------------------------------------------------
!
!     ------------------------------------------------------------------
    character(len=6) :: chnumo, tsca
    character(len=8) :: typech, nomgd, saux08, result_name, sdcarm, carel2, valk2(2)
    character(len=16) :: field_type
    character(len=19) :: cham19, cesnsp, cescoq, cesfib, cesori, cestuy
    character(len=24) :: valk(2), tyres
    character(len=64) :: field_name
!
    integer :: numord, isy, iordr, iret, ibid, codret, nbcham
    integer :: lnochm, nbcmdu, jnosym, ierd
    integer :: jnocha, jliord, nbordr, nbrcmp, jnocmp
    aster_logical :: lfirst, l_mult_model, l_vari_name, l_meta_name
!
    integer, pointer :: numcmp(:) => null()
    character(len=24), pointer :: celk(:) => null()
    parameter   (cesnsp = '&&IREMED.CANBSP')
    parameter   (cescoq = '&&IREMED.CARCOQUE')
    parameter   (cesfib = '&&IREMED.CAFIBR')
    parameter   (cesori = '&&IREMED.CARORIEN')
    parameter   (cestuy = '&&IREMED.CARGEOPO')
!     ------------------------------------------------------------------
    call jemarq()
!
    result_name=nomcon
    lfirst=.true.
!
    call jeveuo(nocham, 'L', jnocha)
    call jelira(nocham, 'LONMAX', nbcham)
!
    call jeveuo(liordr, 'L', jliord)
    call jelira(liordr, 'LONMAX', nbordr)
!
    nbrcmp = 0
    jnocmp = 0
    call jeexin(nomcmp, iret)
    if (iret .ne. 0) then
        call jeveuo(nomcmp, 'L', jnocmp)
        call jelira(nomcmp, 'LONMAX', nbrcmp)
    endif
!
    nbcmdu = 0
    jnosym = 0
    call jeexin(novcmp, iret)
    if (iret .ne. 0) then
        call jeveuo(novcmp, 'L', jnosym)
        if (zk80(jnosym) .eq. ' ') then
            jnosym=0
        else
            call jelira(novcmp, 'LONMAX', nbcmdu)
        endif
    endif
!
    sdcarm = ' '
    if (carael .ne. ' ') then
        if (lresu) then
            call dismoi('CARA_ELEM', nomcon, 'RESULTAT', repk=carel2, arret='C',&
                        ier=ierd)
            if (carel2 .ne. carael) then
                valk2(1) = carael
                valk2(2) = carel2
                call utmess('F', 'MED_64', sk=valk2(1))
            endif
        endif
        sdcarm = '&&IREMED'

        call exisd('CHAMP', carael//'.CANBSP', iret)
        if (iret .ne. 0) then
            call celces(carael//'.CANBSP', 'V', cesnsp)
        endif
        call exisd('CARTE', carael//'.CARORIEN', iret)
        if (iret .ne. 0) then
            call carces(carael//'.CARORIEN', 'ELEM', ' ', 'V', cesori,&
                        'A', iret)
        endif
!
        call exisd('CARTE', carael//'.CARCOQUE', iret)
        if (iret .ne. 0) then
            call carces(carael//'.CARCOQUE', 'ELEM', ' ', 'V', cescoq,&
                        'A', iret)
        endif
!
        call exisd('CARTE', carael//'.CARGEOPO', iret)
        if (iret .ne. 0) then
            call carces(carael//'.CARGEOPO', 'ELEM', ' ', 'V', cestuy,&
                        'A', iret)
        endif
!
        call exisd('CHAM_ELEM', carael//'.CAFIBR', iret)
        if (iret .ne. 0) then
            call celces(carael//'.CAFIBR', 'V', cesfib)
        endif
    endif
!
    if ( linopa.ne.' ' ) then
        call irmpar(nomcon, ifichi, linopa)
    endif
!
!     --- BOUCLE SUR LE NOMBRE DE CHAMPS A IMPRIMER
!
    do isy = 1, nbcham
        l_mult_model = ASTER_FALSE
        l_vari_name  = ASTER_FALSE
        l_meta_name  = ASTER_FALSE
!       --- BOUCLE SUR LA LISTE DES NUMEROS D'ORDRE
!
        do iordr = 1, nbordr
!
!         --- SI VARIABLE DE TYPE RESULTAT = RESULTAT COMPOSE :
!             VERIFICATION CORRESPONDANCE ENTRE NUMERO D'ORDRE
!             UTILISATEUR ORDR(IORDR) ET NUMERO DE RANGEMENT IRET
! AU CAS OU ON NE PASSE PAS EN DESSOUS ON INITIALISE LORDR A FALSE
            if (lresu) then
                call rsutrg(nomcon, zi(jliord+iordr-1), iret, ibid)
                if (iret .eq. 0) then
!             - MESSAGE NUMERO D'ORDRE NON LICITE
                    if (lfirst) then
                        call codent(zi(jliord+iordr-1), 'G', chnumo)
                        call utmess('A', 'PREPOST2_46', sk=chnumo)
                    endif
                    goto 22
                endif
            endif
!
            if (lresu) then
!         * RESULTAT COMPOSE
!           - VERIFICHICATION EXISTENCE DANS LA SD RESULTAT NOMCON
!             DU CHAMP CHAM(ISY) POUR LE NO. D'ORDRE ORDR(IORDR)
!             ET RECUPERATION DANS CHAM19 DU NOM SE LE CHAM_GD EXISTE
                call rsexch(' ', nomcon, zk16(jnocha+isy-1), zi(jliord+ iordr-1), cham19,&
                            iret)
                if (iret .ne. 0) goto 21
            else
!         * CHAM_GD
                cham19 = nomcon
            endif
!
!         * IMPRESSION DU CHAMP (CHAM_NO OU CHAM_ELEM)
!             LE CHAMP EST UN CHAM_GD SIMPLE SI LRESU=.FALSE. OU
!             LE CHAMP EST LE CHAM_GD CHAM(ISY) DE NUMERO D'ORDRE
!             ORDR(IORDR) ISSU DE LA SD_RESULTAT NOMCON
            field_type=zk16(jnocha+isy-1)
            numord=zi(jliord+iordr-1)
!
!       --- TYPE DU CHAMP A IMPRIMER (CHAM_NO OU CHAM_ELEM)
            call dismoi('TYPE_CHAMP', cham19, 'CHAMP', repk=typech)
            call dismoi('TYPE_RESU', result_name, 'RESULTAT', repk=tyres)
!
            if ((typech(1:4).eq.'NOEU') .or. (typech(1:2).eq.'EL')) then
            else if (typech(1:4).eq. 'CART') then
!            GOTO 9999
            else
                valk(1) = typech
                valk(2) = cham19
                if (tyres(1:9) .eq. 'MODE_GENE' .or. tyres(1:9) .eq. 'HARM_GENE') then
                    call utmess('A+', 'PREPOST_87', nk=2, valk=valk)
                    call utmess('A', 'PREPOST6_36')
                else
                    call utmess('A', 'PREPOST_87', nk=2, valk=valk)
                endif
            endif
!
!         --- NOM DE LA GRANDEUR ASSOCIEE AU CHAMP CHAM19
            call dismoi('NOM_GD', cham19, 'CHAMP', repk=nomgd)
            call dismoi('TYPE_SCA', nomgd, 'GRANDEUR', repk=tsca)

            if ((typech(1:4).eq. 'CART'.and. tsca.ne.'R')) then
                if ( .not. lresu ) then
                    valk(1)=tsca
                    call utmess('A+', 'PREPOST_91', nk=1, valk=valk)
                endif
                goto 999
             endif
!
            if (nbrcmp .ne. 0) then
                if ((nomgd.eq.'VARI_R') .and. (typech(1:2).eq.'EL')) then
                    AS_ALLOCATE(vi=numcmp, size=nbrcmp)
! ----------- TRAITEMENT SUR LES "NOMCMP"
                    call utcmp3(nbrcmp, zk8(jnocmp), numcmp)
                    AS_DEALLOCATE(vi=numcmp)
                endif
            endif
! --------- Get name of field in MED file
            field_name = ' '
            saux08 = result_name
            if (nbcmdu .eq. 0) then
                call mdnoch(field_name, lnochm, bool_to_int(lresu), saux08, field_type,&
                            codret)
            else
                field_name = zk80(jnosym+isy-1)(1:64)
            endif
!
!         -- TRAITEMENT SPECIFIQUE POUR LES CHAMPS ISSUE DE PROJ_CHAMP
!            METHODE='SOUS_POINT'
            if (typech .eq. 'ELGA') then
                call jeveuo(cham19//'.CELK', 'L', vk24=celk)
                if (celk(2) .eq. 'INI_SP_MATER') then
                    call utmess('A', 'MED2_9', sk=field_type)
                    codret = 0
                    goto 999
                endif
            endif
!
!         -- ON LANCE L'IMPRESSION:
!         -------------------------
!
            if (.not.lresu) result_name = ' '
            call irchme(ifichi, cham19, partie, field_name, result_name,&
                        field_type, typech, numord, nbrcmp, zk8(jnocmp),&
                        nbnoec, linoec, nbmaec, limaec, lvarie,&
                        sdcarm, carael, linopa, codret)
!
999         continue
!
            if (codret .ne. 0 .and. codret .ne. 100 .and.&
                codret .ne. 200 .and. codret .ne. 300) then
                valk(1) = field_type
                valk(2) = 'MED'
                if (field_type .ne. 'COMPORTEMENT') then
                    call utmess('A', 'PREPOST_90', nk=2, valk=valk)
                endif
            endif
            if (codret .eq. 100) then
                l_mult_model = ASTER_TRUE
            endif
            if (codret .eq. 200) then
                l_vari_name  = ASTER_TRUE
            endif
            if (codret .eq. 400) then
                l_meta_name  = ASTER_TRUE
            endif
!
 22         continue
!
 21         continue
        end do
        if (l_mult_model) then
            valk(1) = field_type
            call utmess('I', 'MED_30', sk=valk(1))
        endif
        if (l_vari_name) then
            call utmess('A', 'MED2_7')
        endif
        if (l_meta_name) then
            call utmess('A', 'MED2_10')
        endif
        lfirst=.false.
!
    end do
!
    call detrsd('CHAM_ELEM_S', cesnsp)
    call detrsd('CHAM_ELEM_S', cescoq)
    call detrsd('CHAM_ELEM_S', cesfib)
    call detrsd('CHAM_ELEM_S', cesori)
    call detrsd('CHAM_ELEM_S', cestuy)
!
    call jedema()
end subroutine
