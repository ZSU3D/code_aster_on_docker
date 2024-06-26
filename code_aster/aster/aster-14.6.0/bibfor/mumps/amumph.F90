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

subroutine amumph(action, solvez, matasz, rsolu, csolu,&
                  vcinez, nbsol, iret, prepos)
!
!
    implicit none
!--------------------------------------------------------------
! BUT : ROUTINE D'INTERFACE ENTRE LE CODE_ASTER ET LA BIBLIOTHEQUE
!       MUMPS DE RESOLUTION DE SYSTEMES LINEAIRES.
!       A UNE MATRICE ASTER CARACTERISEE PAR SON NOM (MATSZ) PEUT
!       CORRESPONDRE PLUSIEURS INSTANCES MUMPS SUIVANT:
!          - LE NUME_DDL ASSOCIE A LA MATR_ASSE,
!          - SON TYPE (R OU C),
!          - SA TAILLE (NU//'.SMOS.SMDI','LONMAX'),
!          - L'ARITHMETIQUE DE LA RESOLUTION MUMPS (SIMPLE OU DOUBLE)
!
! IN : ACTION :
!     /'VERSION' : POUR RECUPERER LE NUMERO DE VERSION (SEULEMENT LA
!              SD_SOLVEUR OU LA MATAS SONT REQUIS). CE NUMERO EST
!              STOCKEE DANS SD_SOLVEUR.SLVK(12). IL DOIT ETRE LICITE
!              (5.1.1/5.1.2(consortium)) SINON UTMESS_F.
!              PAR DEFAUT ON CHERCHE LE NUMERO DS LA SD_SOLVEUR, SINON ON PREND CELUI LIE
!              AU PACKAGE MUMPS LINKE.
!     /'PRERES'  : POUR DEMANDER LES ETAPES ANALYSE+FACTORISATION
!     /'RESOUD'  : POUR DEMANDER LA DESCENTE/REMONTEE
!     /'DETR_MAT': POUR DEMANDER LA DESTRUCTION DE L'INSTANCE MUMPS
!                  ASSOCIEE A UNE MATRICE (ON VA AUSSI DETRUIRE LA
!                  MATRICE, DONC PAS BESOIN DE CONNAITRE LE CONTEXTE
!                  DE RESOLUTION, CAD LA SD_SOLVEUR).
!                  EXEMPLE: DETRSD.
!     /'DETR_OCC': IDEM QUE CI DESSUS MAIS ON NE DETRUIT PAS DS
!                  L'IMMEDIAT LA MATRICE. IL FAUT CONNAITRE PRECISEMENT
!                  LA SD SOLVEUR. EXEMPLE: PRERES.
! IN : SOLVEZ   (K19) : NOM DE LA SD SOLVEUR
!             (SI ACTION=PRERES/RESOUD)
! IN : MATAS (K19) : NOM DE LA MATR_ASSE
!             (SI ACTION=PRERES/RESOUD/DETR_MATR)
! VAR: RSOLU (R)   : EN ENTREE : VECTEUR SECOND MEMBRE (REEL)
!                    EN SORTIE : VECTEUR SOLUTION (REEL)
!             (SI ACTION=RESOUD)
! VAR: CSOLU (C)   : EN ENTREE : VECTEUR SECOND MEMBRE (COMPLEXE)
!                    EN SORTIE : VECTEUR SOLUTION (COMPLEXE)
!             (SI ACTION=RESOUD)
! IN : VCINE (K19) : NOM DU CHAM_NO DE CHARGEMENT CINEMATIQUE
!            (SI ACTION=RESOUD)
! IN : NBSOL (I) : NOMRE DE SYSTEMES A RESOUDRE
! OUT : IRET (I) : CODE_RETOUR :
!            0 : OK
!            1 : ERREUR (DANS LE CAS OU MUMPS EST UTILISE EN PRE_COND)
!            2 : MATRICE NUMERIQUEMENT SINGULIERE
!               (POUR PRERES/TLDLG3 OU OP0014/TLDLGG/TLDLG3)
! IN : PREPOS (LOG) : SI .TRUE. ON FAIT LES PRE ET POSTTRAITEMENTS DE
!           MISE A L'ECHELLE DU RHS ET DE LA SOLUTION (MRCONL) ET DE LA
!           PRISE EN COMPTE DES AFFE_CHAR_CINE (CSMBGG).
!           SI .FALSE. ON NE LES FAIT PAS (PAR EXEMPLE EN MODAL).
!----------------------------------------------------------------------
! person_in_charge: olivier.boiteau at edf.fr
!
#include "asterf_types.h"
#include "asterf.h"
#include "asterfort/amumpc.h"
#include "asterfort/amumpd.h"
#include "asterfort/amumps.h"
#include "asterfort/amumpu.h"
#include "asterfort/amumpz.h"
#include "asterfort/assert.h"
#include "asterfort/dismoi.h"
#include "asterfort/infdbg.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/utmess.h"
#include "mumps/dmumps.h"
    character(len=*) :: action, matasz, vcinez, solvez
    integer :: iret, nbsol
    real(kind=8) :: rsolu(*)
    complex(kind=8) :: csolu(*)
    aster_logical :: prepos
!
#ifdef _HAVE_MUMPS
#include "asterf_mumps.h"
#include "mpif.h"
#include "jeveux.h"
!
    integer :: iprem
    type(smumps_struc), pointer :: smpsk => null()
    type(cmumps_struc), pointer :: cmpsk => null()
    type(dmumps_struc), pointer :: dmpsk => null()
    type(zmumps_struc), pointer :: zmpsk => null()
    integer :: k, ibid, kxmps, jrefa, n, nsmdi, ifm, niv, ifmump, imd
    integer :: nprec, iretz, pcentp(2), ipiv, iretp
    aster_logical :: lbid, lpreco, limpr_matsing
    character(len=1) :: rouc, prec
    character(len=4) :: etam
    character(len=12) :: k12bid
    character(len=14) :: nonu, nu, impr
    character(len=19) :: matas, vcine, nomat, nosolv, solveu
    character(len=24) :: kvers, kpiv
    character(len=24), pointer :: slvk(:) => null()
    integer, pointer :: slvi(:) => null()
!----------------------------------------------------------------
    save iprem
    data  iprem /0/
!----------------------------------------------------------------
    call jemarq()
!
    iretz=0
    call infdbg('SOLVEUR', ifm, niv)
    if ((action(1:6).ne.'PRERES') .and. (action(1:6).ne.'RESOUD') .and.&
        (action(1:8).ne.'DETR_OCC') .and. (action(1:8).ne.'DETR_MAT') .and.&
        (action(1:7).ne.'VERSION')) then
        ASSERT(.false.)
    endif
!
! --- ATTENTION: PARAMETRE DEVELOPPEUR
! --- IMPR : PARAMETRE POUR IMPRIMER LA MATRICE + RHS + EVENTUELLEMENT
!            LA SOLUTION SUR L'UNITE IFMUMP.
!            EN SEQUENTIEL: UN SEUL FICHIER,
!            EN PARALLELE DISTRIBUE, UN FICHIER PAR PROC CONTENANT LA
!               MATRICE LOCALE + RHS (SI PROC 0) +  SOLUTION (SI PROC 0
!               ET SI DEMANDE)
!            EN PARALLELE CENTRALISE, UN FICHIER UNIQUEMENT SUR PROC 0
! --- VALEURS POSSIBLES:
!            = 'NON' RESOLUTION STD SANS ECRITURE FICHIER
!            = 'OUI_SOLVE' ON ECRIT MATRICE/RHS/SOLUTION ET ON RESOUD
!              COMPLETEMENT LE PB COMME EN STD
!            = 'OUI_NOSOLVE' IDEM CI-DESSUS SANS RESOUDRE AFIN
!               DE GAGNER DU TEMPS. LE CALCUL S'ARRETE EN UTMESS_F EN
!              FIN D'ECRITURE DU RHS. ON N'ECRIT PAS DE SOLUTION
    impr='OUI_SOLVE'
    impr='OUI_NOSOLVE'
    impr='NON'
    ifmump=17
! --- FIN BLOC PARAMETRE DEVELOPPEUR
!
    solveu= solvez
    matas=matasz
    vcine=vcinez
!
!
!      0. PHASE D'INITIALISATION
!      ---------------------------
!
    if (iprem .eq. 0) then
        if (impr(1:3) .ne. 'NON') then
            if (impr(1:9) .eq. 'OUI_SOLVE') then
                call utmess('A', 'FACTOR_70', si=ifmump)
            else if (impr(1:11).eq.'OUI_NOSOLVE') then
                call utmess('A', 'FACTOR_71', si=ifmump)
            else
! --- OPTION NON PREVUE
                ASSERT(.false.)
            endif
        endif
!
! INITIALISE LES NMXINS INSTANCES MUMPS POTENTIELLES
! NOMATS (NOM DE LA MATR_ASSE GLOBALE), NONUS (NUM_DDL),
! NOSOLS (SD_SOLVEUR), ETAMS (?), ROUCS (R OU C)
        do k = 1, nmxins
            nomats(k)=' '
            nonus(k)=' '
            nosols(k)=' '
            etams(k)=' '
            roucs(k)=' '
            precs(k)=' '
        enddo
        iprem=1
    endif
!
!      1. RECHERCHE DE KXMPS (NUMERO DE L'INSTANCE XMUMPS) +
!           ROUC (R OU C) :
!      -----------------------------------------------------
    ASSERT(matas.ne.' ')
!
!        Y-A-T-IL DEJA UNE INSTANCE EN MEMOIRE POUR MATAS ?
!
!     ON TESTE LE NOM DE LA MATRICE, CELUI DU NUME_DDL, LE TYPE ET
!     LA TAILLE DU PB ASTER ET DU PB MUMPS ASSOCIE
!
    call dismoi('NOM_NUME_DDL', matas, 'MATR_ASSE', repk=nu)
    call jelira(matas//'.VALM', 'TYPE', cval=rouc)
    nsmdi = 0 
    call jeexin(nu//'.SMOS.SMDI', ibid )
    if ( ibid /= 0 ) then 
       call jelira(nu//'.SMOS.SMDI', 'LONMAX', nsmdi)
    endif 
!
    call jeveuo(matas//'.REFA', 'L', jrefa)
    if (zk24(jrefa-1+11) .eq. 'MATR_DISTR') then
        imd=1
    else
        imd=0
    endif
!
!
! ---  TESTS DE COMPATIBILITE DE SD_SOLVEUR EN FONCTION DE ACTION
    if (solveu .eq. ' ') then
!    -- ON NE CONNAIT PAS LA SD SOLVEUR. ON VIENT SANS DOUTE VIA TLDLGG.
!       ON PREND CELUI ASSOCIE A LA MATRICE
        call dismoi('SOLVEUR', matas, 'MATR_ASSE', repk=solveu)
    endif
!
    prec=' '
    lpreco=.false.
    if (action(1:8) .eq. 'DETR_OCC') then
        ASSERT(solveu.ne.' ')
    endif
    call jeexin(solveu//'.SLVK', ibid)
    if (ibid .ne. 0) then
        call jeveuo(solveu//'.SLVK', 'L', vk24=slvk)
        if (slvk(1)(1:5) .eq. 'MUMPS') then
! --- MUMPS EST-IL UTILISE COMME PRECONDITIONNEUR ?
! --- SI OUI, ON DEBRANCHE LES ALARMES ET INFO (PAS LES UTMESS_F)
            lpreco = slvk(8)(1:3).eq.'OUI'
! --- ON RECUPERE UNIQUEMENT UN NUMERO DE VERSION LICITE
            if (action(1:7) .eq. 'VERSION') then
                if (slvk(12)(1:4) .eq. 'XXXX') then
                    call amumpu(31, rouc, ibid, k12bid, ibid,&
                                lbid, kvers, ibid)
                    slvk(12)=kvers
                else
! --- ON TESTE JUSTE LE CARACTERE LICITE DU NUMERO DE VERSION DEJA
! --- STOCKE DANS LA SD_SOLVEUR
                    kvers=trim(adjustl(slvk(12)))
                    select case (kvers)
                        case('5.1.1','5.1.1consortium','5.1.2','5.1.2consortium')
                    case default
                        call utmess('F', 'FACTOR_72', sk=kvers)
                    end select
                endif
                goto 999
            endif
            if (slvk(7)(1:3) .eq. 'OUI') then
                prec='S'
            else if (slvk(7)(1:3).eq.'NON') then
                prec='D'
            else
! --- ON A OUBLIE UNE INITIALISATION AMONT DE MIXPRE DS .SLVK
!     SAUF POUR CMDE ECLATEE
                if (action(1:5) .ne. 'DETR_') then
                    ASSERT(.false.)
                endif
            endif
        else
!
! --- A PRECISER POUR GCPC AVEC IC SIMPLE PRECISION AVEC MUMPS
            ASSERT(.false.)
        endif
    else
! --- ON DOIT AVOIR UNE SD_SOLVEUR.SLVK POUR CETTE OPTION
        if ((action(1:8).eq.'DETR_OCC') .or. (action(1:7).eq.'VERSION')) then
            ASSERT(.false.)
        endif
    endif
!
    kxmps=1
    do k = 1, nmxins
! ----- ASTUCE POUR DETRUIRE TOUTES LES OCCURENCES (QQES SOIT LEUR
!       ARITHMETIQUE) ASSOCIEES A UNE MATRICE SI 'DETR_MAT'
        if (action(1:8) .eq. 'DETR_MAT') prec=precs(k)
        if ((nomats(k).eq.matas) .and. (nonus(k).eq.nu) .and. (roucs(k) .eq.rouc) .and.&
            (precs(k).eq.prec)) then
            if (rouc .eq. 'R') then
                if (prec .eq. 'S') then
                    smpsk=>smps(k)
                    n=smpsk%n
                else if (prec.eq.'D') then
                    dmpsk=>dmps(k)
                    n=dmpsk%n
                else
                    ASSERT(.false.)
                endif
            else if (rouc.eq.'C') then
                if (prec .eq. 'S') then
                    cmpsk=>cmps(k)
                    n=cmpsk%n
                else if (prec.eq.'D') then
                    zmpsk=>zmps(k)
                    n=zmpsk%n
                else
                    ASSERT(.false.)
                endif
            else
                ASSERT(.false.)
            endif
            if (((nsmdi.eq.n).and.(imd.eq.0)) .or. (imd.eq.1)) then
                kxmps=k
                rouc=roucs(k)
                prec=precs(k)
                goto 2
            endif
        endif
    end do
    if (action(1:5) .eq. 'DETR_') goto 999
!
!        Y-A-T-IL ENCORE UNE PLACE LIBRE ?
    do k = 1, nmxins
        if (nomats(k) .eq. ' ') then
            kxmps=k
            call jelira(matas//'.VALM', 'TYPE', cval=rouc)
            goto 2
        endif
    end do
    call utmess('F', 'FACTOR_60')
  2 continue
!
!
!     2. QUELQUES VERIFICATIONS ET PETITES ACTIONS :
!     ----------------------------------------------
    if (action(1:6) .eq. 'PRERES') then
        call dismoi('NOM_NUME_DDL', matas, 'MATR_ASSE', repk=nu)
        ASSERT(solveu.ne.' ')
        ASSERT(nomats(kxmps).eq.' ')
        ASSERT(nosols(kxmps).eq.' ')
        ASSERT(nonus(kxmps).eq.' ')
        ASSERT(etams(kxmps).eq.' ')
        ASSERT(roucs(kxmps).eq.' ')
        ASSERT(precs(kxmps).eq.' ')
        etam='FNUM'
        nomat=matas
        nosolv=solveu
        nonu=nu
        nomats(kxmps)=nomat
        nosols(kxmps)=nosolv
        etams(kxmps)=etam
        nonus(kxmps)=nonu
        roucs(kxmps)=rouc
        precs(kxmps)=prec

        call jeveuo(nomat//'.REFA', 'E', jrefa)
        zk24(jrefa-1+8)='DECT'

!        --- PARAMETRE NPREC
        call jeveuo(nosolv//'.SLVI', 'L', vi=slvi)
        nprec=slvi(1)
!
    else if (action(1:6).eq.'RESOUD') then
        ASSERT(nbsol.ge.1)
        nomat=nomats(kxmps)
        nosolv=nosols(kxmps)
        etam=etams(kxmps)
        nonu=nonus(kxmps)
        rouc=roucs(kxmps)
        prec=precs(kxmps)
!
        ASSERT(solveu.ne.' ')
        if (imd .eq. 0) then
            ASSERT(solveu.eq.nosolv)
            ASSERT(etam.eq.'FNUM')
        endif
        call dismoi('NOM_NUME_DDL', matas, 'MATR_ASSE', repk=nu)
        ASSERT(nonu.eq.nu)
!
    else if (action(1:5).eq.'DETR_') then
        nomat=nomats(kxmps)
        ASSERT(matas.ne.' ')
!
    else
        ASSERT(.false.)
    endif
!
!        --- SI GESTION_MEMOIRE='AUTO'
!        --- PARAMETRES POUR LA GESTION DE PCENT_PIVOT/ELIM_LAGR='LAGR2'
!        --- PCENTP(1) --> NBRE TENTATIVES DE FACTO.
!        --- PCENTP(2) --> TERME MULTIPLICATIF DE PCENT_PIVOT ENTRE DEUX
!            TENTATIVES DE FACTO.:
!                    PCENT_PIVOT_NEW=PCENT_PIVOT_OLD*PCENTP(2)
    pcentp(1)=5
    pcentp(2)=2
    if (rouc .eq. 'R') then
        if (prec .eq. 'S') then
            call amumps(action, kxmps, rsolu, vcine, nbsol,&
                        iretz, impr, ifmump, prepos, pcentp)
        else if (prec.eq.'D') then
            call amumpd(action, kxmps, rsolu, vcine, nbsol,&
                        iretz, impr, ifmump, prepos, pcentp)
        else
            ASSERT(.false.)
        endif
    else if (rouc.eq.'C') then
        if (prec .eq. 'S') then
            call amumpc(action, kxmps, csolu, vcine, nbsol,&
                        iretz, impr, ifmump, prepos, pcentp)
        else if (prec.eq.'D') then
            call amumpz(action, kxmps, csolu, vcine, nbsol,&
                        iretz, impr, ifmump, prepos, pcentp)
        else
            ASSERT(.false.)
        endif
    else
        ASSERT(.false.)
    endif
!
! --- NETTOYAGE DES OCCURENCES MUMPS EN MODE GESTION_MEMOIRE='EVAL' POUR
! --- PAR EXEMPLE NE PAS DEPASSER 5 OCCURENCES SIMULTANNEES EN CAS
! --- D'USAGE DU MECANISME TRY_EXCEPT PYTHON
    if ((action(1:6).eq.'PRERES') .and. (slvk(9)(1:4).eq.'EVAL')) then
        if (rouc .eq. 'R') then
            if (prec .eq. 'S') then
                call amumps('DETR_OCC', kxmps, rsolu, vcine, nbsol,&
                            iretz, impr, ifmump, prepos, pcentp)
            else if (prec.eq.'D') then
                call amumpd('DETR_OCC', kxmps, rsolu, vcine, nbsol,&
                            iretz, impr, ifmump, prepos, pcentp)
            endif
        else if (rouc.eq.'C') then
            if (prec .eq. 'S') then
                call amumpc('DETR_OCC', kxmps, csolu, vcine, nbsol,&
                            iretz, impr, ifmump, prepos, pcentp)
            else if (prec.eq.'D') then
                call amumpz('DETR_OCC', kxmps, csolu, vcine, nbsol,&
                            iretz, impr, ifmump, prepos, pcentp)
            endif
        endif
        call utmess('F', 'FACTOR_77')
    endif
!
! --- GESTION DES CODES RETOUR EN CAS DE DETECTION DE SINGULARITES
    if (action(1:6) .eq. 'PRERES') then
        ASSERT((iretz.eq.0).or.(iretz.eq.1).or.(iretz.eq.2))
! --- ATTENTION: PARAMETRE DEVELOPPEUR A DECOMMENTER POUR SORTIR LA MATRICE ET LE RHS
! --- NON PAS SUR LE PREMIER SYSTEME RENCONTRE (CF. DEBUT DU FICHIER) MAIS SUR LE DERNIER
! --- AVANT UN UTMESS_F DU FAIT D'UNE MATRICE SINGULIERE
!        limpr_matsing=.true.
        limpr_matsing=.false.
        if (limpr_matsing) then
            kpiv='&&AMUMP.PIVNUL'
            iretp=0
            call jeexin(kpiv, iretp)
            if (iretp .ne. 0) then
                call jeveuo(kpiv, 'L', ipiv)
            else
                ASSERT(.false.)
            endif
            if (zi(ipiv).gt.0) then
                dmpsk=>dmps(kxmps)
                deallocate(dmpsk%a,stat=ibid)
                deallocate(dmpsk%irn,stat=ibid)
                deallocate(dmpsk%jcn,stat=ibid)
                dmpsk%job = -2
                call dmumps(dmpsk)
                call jedetr(kpiv)
                impr='OUI_NOSOLVE'
                call amumpd(action, kxmps, rsolu, vcine, nbsol,&
                            iretz, impr, ifmump, prepos, pcentp)
                call utmess('F', 'FACTOR_71', si=ifmump)
            endif
        endif
        if (iretz .eq. 2) then
            if (nprec .lt. 0) then
! --- FONCTIONNALITE DE DETECTION DE SINGULARITE NON ACTIVEE:
!                                               STOP EN UTMESS_F
                call utmess('F', 'FACTOR_42')
            else
! --- FONCTIONNALITE DE DETECTION DE SINGULARITE ACTIVEE:
!                                    ALARME + GESTION DU PB VIA TLDLG3
                if (.not.lpreco) then
                    call utmess('A', 'FACTOR_42')
                endif
            endif
        endif
    endif
!
999 continue
    if ((iretz.ne.0) .and. (iretz.ne.1) .and. (iretz.ne.2)) then
! --- VALEUR ILLICITE
        ASSERT(.false.)
    else
! --- ON PEUT FOURNIR L'OUTPUT
        iret=iretz
    endif
    call jedema()
!
#else
    call utmess('F', 'FERMETUR_1')
!
#endif
end subroutine
