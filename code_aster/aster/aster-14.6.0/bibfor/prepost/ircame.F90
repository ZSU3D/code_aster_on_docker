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
! aslint: disable=W1504
!
subroutine ircame(ifi, nochmd, chanom, typech, modele,&
                  nbcmp, nomcmp, etiqcp, partie, numpt,&
                  instan, numord, adsk, adsd, adsc,&
                  adsv, adsl, nbenec, lienec, sdcarm,&
                  carael, field_type, codret)
!
implicit none
!
#include "asterf_types.h"
#include "MeshTypes_type.h"
#include "jeveux.h"
#include "asterfort/codent.h"
#include "asterfort/infniv.h"
#include "asterfort/ircam1.h"
#include "asterfort/ircmpr.h"
#include "asterfort/irelst.h"
#include "asterfort/irmail.h"
#include "asterfort/irmpga.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/lrmtyp.h"
#include "asterfort/mdexch.h"
#include "asterfort/mdexma.h"
#include "asterfort/mdnoma.h"
#include "asterfort/ulisog.h"
#include "asterfort/utlicm.h"
#include "asterfort/utmess.h"
!
character(len=8) :: typech, modele, sdcarm, carael
character(len=19) :: chanom
character(len=64) :: nochmd
character(len=*) :: nomcmp(*), partie, etiqcp
integer :: nbcmp, numpt, numord, ifi
integer :: adsk, adsd, adsc, adsv, adsl
integer :: nbenec
integer :: lienec(*)
integer :: typent, tygeom
real(kind=8) :: instan
character(len=16), intent(in) :: field_type
integer :: codret
!
! --------------------------------------------------------------------------------------------------
!
!     ECRITURE D'UN CHAMP - FORMAT MED
!
! --------------------------------------------------------------------------------------------------
!
!     ENTREES :
!       IFI    : UNITE LOGIQUE D'IMPRESSION DU CHAMP
!       NOCHMD : NOM MED DU CHAMP A ECRIRE
!       PARTIE: IMPRESSION DE LA PARTIE IMAGINAIRE OU REELLE POUR
!               UN CHAMP COMPLEXE
!       CHANOM : NOM ASTER DU CHAM A ECRIRE
!       TYPECH : TYPE DU CHAMP ('NOEU', 'ELNO', 'ELGA')
!       MODELE : MODELE ASSOCIE AU CHAMP
!       NBCMP  : NOMBRE DE COMPOSANTES A ECRIRE. S'IL EST NUL, ON
!                PREND TOUT
!       NOMCMP : NOMS DES COMPOSANTES A ECRIRE
!       NUMPT  : NUMERO DE PAS DE TEMPS
!       INSTAN : VALEUR DE L'INSTANT A ARCHIVER
!       NUMORD : NUMERO D'ORDRE DU CHAMP
!       ADSK, D, ... : ADRESSES DES TABLEAUX DES CHAMPS SIMPLIFIES
!       NBVATO : NOMBRE DE VALEURS TOTALES
!       NBENEC : NOMBRE D'ENTITES A ECRIRE (O, SI TOUTES)
!       LIENEC : LISTE DES ENTITES A ECRIRE SI EXTRAIT
!       SDCARM : CARA_ELEM (UTILE POUR LES SOUS-POINTS)
! In  field_type       : type of field (symbolic name in result datastructure)
!     SORTIES:
!       CODRET : CODE DE RETOUR (0 : PAS DE PB, NON NUL SI PB)
!
! --------------------------------------------------------------------------------------------------
!
    character(len=6), parameter :: nompro = 'IRCAME'
    integer, parameter :: ednoeu=3, edmail=0, ednoma=4, typnoe=0
    character(len=1)   :: saux01
    character(len=8)   :: saux08, nomaas, nomtyp(MT_NTYMAX)
    character(len=16)  :: formar
    character(len=24)  :: ntlcmp, ntncmp, ntucmp, ntproa, nmcmfi, ncaimi, ncaimk
    character(len=64)  :: nomamd
    character(len=200) :: nofimd
    character(len=255) :: kfic
    med_idt :: ifimed
    integer :: nbtyp, ifm, nivinf, lnomam
    integer :: ncmpve, nvalec, nbprof, nbvato, ncmprf
    integer :: nbimpr, jnocm1, jnocm2, nbcmp2, icmp1, icmp2
    integer :: adcaii, adcaik
    integer :: iaux, jaux, nrimpr
    integer :: existc, nbcmfi, nbval
    aster_logical :: lgaux, existm
!
! --------------------------------------------------------------------------------------------------
!
    integer :: typgeo(MT_NTYMAX)
    integer :: nnotyp(MT_NTYMAX)
    integer :: modnum(MT_NTYMAX)
    integer :: numnoa(MT_NTYMAX, MT_NNOMAX), nuanom(MT_NTYMAX, MT_NNOMAX)
    integer :: renumd(MT_NTYMAX)
!
! --------------------------------------------------------------------------------------------------
!
    call jemarq()
!
! 1. PREALABLES
!   1.1. ==> RECUPERATION DU NIVEAU D'IMPRESSION
    call infniv(ifm, nivinf)
!   1.2. ==> NOMS DES TABLEAUX DE TRAVAIL
!             12   345678   9012345678901234
    ntlcmp = '&&'//nompro//'.LISTE_N0MCMP   '
    ntncmp = '&&'//nompro//'.NOMCMP         '
    ntucmp = '&&'//nompro//'.UNITECMP       '
    ntproa = '&&'//nompro//'.PROFIL_ASTER   '
    nmcmfi = '&&'//nompro//'.NOMCMP_FICHIER '
    ncaimi = '&&'//nompro//'.CARAC_NOMBRES__'
    ncaimk = '&&'//nompro//'.CARAC_CHAINES__'
!   1.3. ==> NOM DU FICHIER MED
    call ulisog(ifi, kfic, saux01)
    if (kfic(1:1) .eq. ' ') then
        call codent(ifi, 'G', saux08)
        nofimd = 'fort.'//saux08
    else
        nofimd = kfic(1:200)
    endif
!
    if (nivinf .gt. 1) then
        write (ifm,*) '<',nompro,'> NOM DU FICHIER MED : ',nofimd
    endif
!   1.4. ==> LES NOMBRES CARACTERISTIQUES
    nbvato = zi(adsd)
    ncmprf = zi(adsd+1)
!
! 2. LE MAILLAGE
!   2.1. ==> NOM DU MAILLAGE ASTER
    nomaas = zk8(adsk-1+1)
!   Generate name of mesh for MED
    call mdnoma(nomamd, lnomam, nomaas, codret)
!   2.3. ==> CE MAILLAGE EST-IL DEJA PRESENT DANS LE FICHIER ?
    iaux = 0
    ifimed = 0
    call mdexma(nofimd, ifimed, nomamd, iaux, existm, jaux, codret)
!   2.4. ==> SI LE MAILLAGE EST ABSENT, ON L'ECRIT
    if (.not.existm) then
        saux08 = 'MED     '
        lgaux = .false.
        formar=' '
        call irmail(saux08, ifi, iaux, nomaas, lgaux, modele, nivinf, formar)
    endif
!
! 3. PREPARATION DU CHAMP A ECRIRE
!   3.1. ==> NUMEROS, NOMS ET UNITES DES COMPOSANTES A ECRIRE
    call utlicm(nbcmp, nomcmp, zk8(adsk+1), ncmprf, zk8(adsc),&
                ncmpve, ntlcmp, ntncmp, ntucmp)
    if (ncmpve .gt. 80) then
        call utmess('A', 'MED_99', sk=nochmd)
        goto 999
    endif
!   ON REMPLACE LES NOMS DES COMPOSANTES
    if (etiqcp .ne. ' ') then
        call jeveuo(ntncmp, 'L', jnocm1)
        call jeveuo(etiqcp, 'L', jnocm2)
        call jelira(etiqcp, 'LONMAX', nbcmp2)
        nbcmp2=nbcmp2/2
        do icmp1 = 1, ncmpve
            do icmp2 = 1, nbcmp2
                if (zk16(jnocm1+icmp1-1) .eq. zk16(jnocm2+2*(icmp2-1))) then
                    zk16(jnocm1+icmp1-1) = zk16(jnocm2+2*icmp2-1)
                    goto 10
                endif
            enddo
 10         continue
        enddo
    endif
!   3.2. ==> RECUPERATION DES NB/NOMS/NBNO/NBITEM DES TYPES DE MAILLESDANS CATALOGUE
!            RECUPERATION DES TYPES GEOMETRIE CORRESPONDANT POUR MED
!            VERIF COHERENCE AVEC LE CATALOGUE
    call lrmtyp(nbtyp, nomtyp, nnotyp, typgeo, renumd,&
                modnum, nuanom, numnoa)
!   3.3. ==> DEFINITIONS DES IMPRESSIONS ET CREATION DES PROFILS EVENTUELS
    call ircmpr(nofimd, typech, nbimpr, ncaimi, ncaimk,&
                ncmprf, ncmpve, ntlcmp, nbvato, nbenec,&
                lienec, adsd, adsl, nomaas, modele,&
                typgeo, nomtyp, ntproa, chanom, sdcarm,&
                field_type)
!
    if ( nbimpr.gt.0 ) then
        call jeveuo(ncaimi, 'L', adcaii)
        call jeveuo(ncaimk, 'L', adcaik)
!       3.4. ==> CARACTERISATION DES SUPPORTS QUAND CE NE SONT PAS DES NOEUDS
        if (typech(1:4) .eq. 'ELGA' .or. typech(1:4) .eq. 'ELEM') then
            if (sdcarm .ne. ' ' .and. typech(1:4) .eq. 'ELGA') then
                call irelst(nofimd, chanom, nochmd,     typech,       nomaas,&
                            nomamd, nbimpr, zi(adcaii), zk80(adcaik), sdcarm, carael)
            endif
            call irmpga(nofimd, chanom,     nochmd,       typech, nomtyp,&
                        nbimpr, zi(adcaii), zk80(adcaik), modnum, nuanom, sdcarm, codret)
        endif
!
!       Reperage du champ : existe-t-il deja ?
!       on doit parcourir toutes les impressions possibles pour ce champ
        existc = 0
        do nrimpr = 1 , nbimpr
            if (codret .eq. 0) then
                tygeom = zi(adcaii+10*nrimpr-2)
                if (tygeom .eq. typnoe) then
                    typent = ednoeu
                else
                    if (typech .eq. 'ELNO') then
                        typent = ednoma
                    else
                        typent = edmail
                    endif
                endif
                nvalec = zi(adcaii+10*nrimpr-4)
                call jedetr(nmcmfi)
                ifimed = 0
                call mdexch(nofimd, ifimed, nochmd, numpt, numord,&
                            ncmpve, ntncmp, nvalec, typent, tygeom,&
                            jaux, nbcmfi, nmcmfi, nbval, nbprof,&
                            codret)
                existc = max ( existc, jaux )
            endif
        enddo
!
!       ECRITURE SI C'EST POSSIBLE
        if ( existc.le.2 ) then
            call ircam1(nofimd, nochmd, existc, ncmprf, numpt,&
                        instan, numord, adsd, adsv, adsl,&
                        adsk, partie, ncmpve, ntlcmp, ntncmp,&
                        ntucmp, ntproa, nbimpr, zi(adcaii), zk80(adcaik),&
                        typech, nomamd, nomtyp, modnum, numnoa,&
                        codret)
        else
            call utmess('F', 'MED2_4', sk=nochmd, sr=instan)
        endif
    else
        call utmess('A', 'MED_82', sk=nochmd)
    endif
!
999 continue
    if (nivinf .gt. 1) then
        write (ifm,*) ' '
    endif
!
    call jedetr('&&'//nompro//'.LISTE_N0MCMP   ')
    call jedetr('&&'//nompro//'.NOMCMP         ')
    call jedetr('&&'//nompro//'.UNITECMP       ')
    call jedetr('&&'//nompro//'.PROFIL_ASTER   ')
    call jedetr('&&'//nompro//'.NOMCMP_FICHIER ')
    call jedetr('&&'//nompro//'.CARAC_NOMBRES__')
    call jedetr('&&'//nompro//'.CARAC_CHAINES__')
!
    call jedema()
!
end subroutine
