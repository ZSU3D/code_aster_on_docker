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

subroutine ascalc(resu, masse, mome, psmo, stat,&
                  nbmode, neq, nordr, knomsy, nbopt,&
                  ndir, monoap, muapde, nbsup, nsupp,&
                  typcmo, temps, comdir, typcdi, tronc,&
                  amort, spectr, gamma0, nomsup, reasup,&
                  depsup, tcosup, corfre, f1gup, f2gup)
! aslint: disable=W1306,W1504
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getfac.h"
#include "asterfort/asacce.h"
#include "asterfort/ascorm.h"
#include "asterfort/asdir.h"
#include "asterfort/asecon.h"
#include "asterfort/asefen.h"
#include "asterfort/assert.h"
#include "asterfort/asstoc.h"
#include "asterfort/astron.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvem.h"
#include "asterfort/getvtx.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jeexin.h"
#include "asterfort/jelira.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexnom.h"
#include "asterfort/jexnum.h"
#include "asterfort/rsexch.h"
#include "asterfort/utmess.h"
#include "asterfort/vprecu.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_deallocate.h"
#include "asterfort/as_allocate.h"
!
    integer :: ndir(*), tcosup(*), nordr(*), nsupp(*)
    real(kind=8) :: amort(*), spectr(*), gamma0(*), depsup(*), reasup(*)
    real(kind=8) :: f1gup, f2gup
    character(len=*) :: resu, masse, mome, psmo, stat, typcmo, typcdi, knomsy(*)
    character(len=*) :: nomsup(*)
    aster_logical :: monoap, muapde, comdir, tronc, corfre
!
!     UTILISE PAR LA COMMANDE : COMB_SISM_MODAL
!
!     ------------------------------------------------------------------
! IN  : RESU   : NOM UTILISATEUR DE LA COMMANDE
! IN  : MASSE  : MATRICE ASSEMBLEE
! IN  : MOME   : MODES MECANIQUES
! IN  : PSMO   : PSEUDO-MODES (SI PRISE EN COMPTE DE LA TRONCATURE)
! IN  : STAT   : MODE STATIQUES (CAS MULTI-SUPPORT)
! IN  : NBMODE : NOMBRE DE MODES
! IN  : NEQ    : NOMBRE D'EQUATIONS
! IN  : NORDR  : NUMERO D'ORDRE DES MODES MECANIQUES
! IN  : KNOMSY : LES OPTIONS DE CALCUL
! IN  : NBOPT  : NOMBRE D'OPTION DE CALCUL
! IN  : NDIR   : DIRECTIONS DE CALCUL
! IN  : MONOAP : =.TRUE.  , CAS DU MONO-SUPPORT
!                =.FALSE. , CAS DU MULTI-SUPPORT
! IN  : MUAPDE : =.TRUE.  , CAS DU MULTI-SUPPORTS DECORRELES
!                =.FALSE. , CAS DU MULTI-SUPPORTS CORRELES
! IN  : NBSUP  : NOMBRE DE SUPPORT
! IN  : NSUPP  : MAX DU NOMBRE DE SUPPORT PAR DIRECTION
! IN  : TYPCMO : TYPE DE RECOMBINAISON DES MODES
! IN  : TEMPS  : DUREE FORTE DU SEISME (TYPCMO='DSC')
! IN  : COMDIR : =.TRUE.  , COMBINAISON DES DIRECTIONS
!                =.FALSE. , PAS DE COMBINAISON DES DIRECTIONS
! IN  : TYPCDI : TYPE DE COMBINAISON DES DIRECTIONS
! IN  : TRONC  : =.TRUE.  , PRISE EN COMPTE DE LA TRONCATURE
!                =.FALSE. , PAS DE PRISE EN COMPTE DE LA TRONCATURE
! IN  : AMORT  : VECTEUR DES AMORTISSEMENTS MODAUX
! IN  : SPECTR : TABLEAU DES VALEURS SPECTRALES
! IN  : GAMMA0 : TABLEAU DES CORRECTIONS STATIQUES (PAR SUPPORT ET DIRECTION)
! IN  : NOMSUP : VECTEUR DES NOMS DES SUPPORTS
! IN  : REASUP : VECTEUR DES REACTIONS MODALES AUX SUPPORTS
! IN  : DEPSUP : VECTEUR DES DEPLACEMENTS DES SUPPORTS
! IN  : TCOSUP : TYPE DE RECOMBINAISON DES SUPPORTS
! IN  : CORFRE : =.TRUE.  , CORRECTION DES FREQUENCES
! IN  : F1GUP  : FREQUENCE F1 POUR LA METHODE DE GUPTA
! IN  : F2GUP  : FREQUENCE F2 POUR LA METHODE DE GUPTA
!     ------------------------------------------------------------------
    integer :: id, iopt, iret, jcrer, jcrep, jdir, jmod, jrep1, jtabs
    integer :: nbmode, nbopt, nbpara, nbpari, nbpark, nbparr, nbsup, ndepl
    integer :: neq, jrep2, nbdis(3, nbsup), noc, ioc, n1, nno, is, ino, igr
    integer :: ngr, jdgn, ier, ncompt, nintra, nbvect
    parameter     ( nbpara = 5 )
    real(kind=8) :: temps
    aster_logical :: prim, secon, glob
    character(len=4) :: ctyp
    character(len=8) :: k8b, noeu, noma
    character(len=15) :: motfa1
    character(len=16) :: nomsy, nomsy2, nopara(nbpara)
    character(len=19) :: kvec, kval, moncha
    character(len=24) :: kvx1, kvx2, kve2, kve3, kve4, kve5, obj1, obj2
    character(len=24) :: grnoeu, valk(2)
    integer :: iarg
    character(len=24), pointer :: group_no(:) => null()
    character(len=8), pointer :: noeud(:) => null()
!
    data  nopara /        'OMEGA2'          , 'MASS_GENE'       ,&
     &  'FACT_PARTICI_DX' , 'FACT_PARTICI_DY' , 'FACT_PARTICI_DZ'  /
!     ------------------------------------------------------------------
!
    call jemarq()
    kvec = '&&ASCALC.VAL_PROPRE'
    kval = '&&ASCALC.GRAN_MODAL'
    kvx1 = '&&ASCALC.REP_MO1'
    kvx2 = '&&ASCALC.REP_MO2'
    kve2 = '&&ASCALC.C_REP_MOD_PER'
    kve3 = '&&ASCALC.REP_DIR'
    kve4 = '&&ASCALC.TABS'
    kve5 = '&&ASCALC.C_REP_MOD_RIG'
    call rsexch('F', mome, 'DEPL', 1, moncha,&
                ier)
!
    call getfac('COMB_DEPL_APPUI', ndepl)
    if (ndepl .ne. 0) then
        prim = .true.
        secon =.true.
        glob = .false.
    else
        prim = .false.
        secon =.false.
        glob = .true.
    endif
!
!
!  ----         CAS DECORRELE            ----
!  ---- INITIALISATION DU TABLEAU CONCERNANT
!  ---- LES REGROUPEMENTS EN INTRA-GROUPE
    do id = 1, 3
        do is = 1, nbsup
            nbdis(id, is) = 0
        end do
    end do

    nintra = nbsup
    noc = nbsup

!
!  ---- CONSTITUTION DES GROUPES D'APPUI ----
    if ((.not.monoap) .and. muapde) then
        motfa1 = 'GROUP_APPUI'
        call getfac(motfa1, noc)
!  ---- SI GROUP_APPUI EST PRESENT ----
        if (noc .ne. 0) then
            do ioc = 1, noc
                call getvtx(motfa1, 'NOEUD', iocc=ioc, nbval=0, nbret=n1)
                if (n1 .ne. 0) then
                    nno = -n1
                    AS_ALLOCATE(vk8=noeud, size=nno)
                    call getvtx(motfa1, 'NOEUD', iocc=ioc, nbval=nno, vect=noeud,&
                                nbret=n1)
                    do ino = 1, nno
                        noeu = noeud(ino)
                        call getvtx(motfa1, 'NOEUD', iocc=ioc, nbval=0, nbret=n1)
                        do id = 1, 3
                            do is = 1, nsupp(id)
                                if (nomsup((id-1)*nbsup+is) .eq. noeu) then
                                    if (nbdis(id, is) .ne. 0) then
                                        call utmess('F', 'SEISME_93', sk=noeu)
                                    endif
                                    nbdis(id, is) = ioc
                                endif
                            end do
                        end do
                    end do
                    AS_DEALLOCATE(vk8=noeud)
                else
                    call dismoi('NOM_MAILLA', masse, 'MATR_ASSE', repk=noma)
                    obj1 = noma//'.GROUPENO'
                    obj2 = noma//'.NOMNOE'
                    call getvem(noma, 'GROUP_NO', motfa1, 'GROUP_NO', ioc,&
                                iarg, 0, k8b, n1)
                    if (n1 .ne. 0) then
                        ngr = -n1
                        AS_ALLOCATE(vk24=group_no, size=ngr)
                        call getvem(noma, 'GROUP_NO', motfa1, 'GROUP_NO', ioc,&
                                    iarg, ngr, group_no, n1)
                        do igr = 1, ngr
                            grnoeu = group_no(igr)
                            call jeexin(jexnom(obj1, grnoeu), iret)
                            if (iret .eq. 0) then
                                ier = ier + 1
                                ASSERT(iret .ne. 0)
                            endif
                            call jelira(jexnom(obj1, grnoeu), 'LONUTI', nno)
                            call jeveuo(jexnom(obj1, grnoeu), 'L', jdgn)
!
                            do ino = 1, nno
                                call jenuno(jexnum(obj2, zi(jdgn+ino-1) ), noeu)
                                do id = 1, 3
                                    do is = 1, nsupp(id)
                                        if (nomsup((id-1)*nbsup+is) .eq. noeu) then
                                            if (nbdis(id, is) .ne. 0) then
                                                valk(1) = noeu
                                                valk(2) = grnoeu
                                                call utmess('F', 'SEISME_94', nk=2,&
                                                    valk=valk)
                                            endif
                                            nbdis(id, is) = ioc
                                        endif
                                    end do
                                end do
                            end do
                        end do
                        AS_DEALLOCATE(vk24=group_no)
                    endif
                endif
            end do
            if (noc .eq. 1) then
                do id = 1, 3
                    ncompt = 0
                    do is = 1, nsupp(id)
                        ncompt = ncompt + nbdis(id, is)
                    end do
                end do
                if (ncompt .eq. nbsup) then
                    call utmess('F', 'SEISME_30')
                endif
            endif
        endif
!  ---- SI GROUP_APPUI EST ABSENT ----
        nintra = -1
        do id = 1, 3
            ncompt = 0
            do is = 1, nsupp(id)
                if (nbdis(id, is) .eq. 0) then
                    ncompt = ncompt + 1
                    nbdis(id, is) = noc + ncompt
                endif
            end do
            if (noc + ncompt .gt. nintra) nintra = noc + ncompt
        end do
    else
!  ---- SI LES EXCITATIONS SONT CORRELEES ----
        do id = 1, 3
            ncompt = 0
            do is = 1, nbsup
                ncompt = ncompt + 1
                nbdis(id, is) = ncompt
            end do
        end do
        nintra = nbsup
    endif
!
!
!     --- BOUCLE SUR LES OPTIONS DE CALCUL "NOMSY" ---
    do iopt = 1, nbopt
        nomsy = knomsy(iopt)
        nomsy2 = nomsy
        if (nomsy(1:4) .eq. 'VITE') nomsy2 = 'DEPL'
        if (nomsy(1:4) .eq. 'ACCE') nomsy2 = 'DEPL'
        nbvect = nbmode
        call vprecu(mome, nomsy2, nbvect, nordr, kvec,&
                    nbpara, nopara(1), k8b, kval, k8b,&
                    neq, nbmode, ctyp, nbpari, nbparr,&
                    nbpark)
        call jeveuo(kvec, 'L', jmod)
        call wkvect(kvx1, 'V V R', 3*neq*nbsup, jrep1)
        call wkvect(kvx2, 'V V R', 3*neq*nbsup, jrep2)
        call wkvect(kve2, 'V V R', 3*neq*nbsup, jcrep)
        call wkvect(kve3, 'V V R', 3*neq, jdir)
        call wkvect(kve4, 'V V R', nbsup*neq, jtabs)
        call wkvect(kve5, 'V V R', 3*neq*nbsup, jcrer)
!
!        ---------------------------------------------------------------
!                        REPONSE PRIMAIRE OU GLOBAL
!        ---------------------------------------------------------------
!
!        --- BOUCLE SUR LES DIRECTIONS ----
        do id = 1, 3
            if (ndir(id) .eq. 1) then
!
!              --- CALCUL DES REPONSE MODALES ---
!
!              --- COMBINAISON DES REPONSES MODALES ---
!
                call ascorm(monoap, typcmo, nbsup, nsupp, neq,&
                            nbmode, zr(jrep1), zr(jrep2), amort, mome,&
                            id, temps, zr(jcrer), zr(jcrep), zr(jtabs),&
                            nomsy, zr(jmod), reasup, spectr, corfre,&
                            muapde, tcosup, nintra, nbdis, f1gup,&
                            f2gup, nopara, nordr)
!
!              --- PRISE EN COMPTE DES EFFETS D'ENTRAINEMENT ---
!              --- DANS LE CAS DE CALCUL DE REPONSE GLOBALE  ---
!
                if ((.not.monoap) .and. glob) then
                    call asefen(muapde, nomsy2, id, stat, neq,&
                                nbsup, ndir, nsupp, masse, nomsup,&
                                depsup, zr(jcrep), nintra, nbdis)
                endif
!
!              --- PRISE EN COMPTE DE LA TRONCATURE ---
!              --- DANS LE CAS DE CALCUL DE REPONSE GLOBALE  ---
!
                if (tronc) then
                    call astron(nomsy, psmo, monoap, muapde, nbsup,&
                                nsupp, neq, nbmode, id, zr(jmod),&
                                mome, gamma0, nomsup, reasup, zr(jcrer),&
                                zr(jcrep), nopara, nordr)
                endif
!
!              ----CALCUL DE L ACCELERATION ABSOLUE
!
                call asacce(nomsy, monoap, nbsup, neq,&
                            nbmode, id, moncha, zr(jmod), mome,&
                            gamma0, zr( jcrer), zr(jcrep), nbdis, nopara,&
                            nordr)
!
!              --- CALCUL DES RECOMBINAISONS PAR DIRECTIONS---
                call asdir(monoap, muapde, id, neq, nbsup,&
                           nsupp, tcosup, zr(jcrep), zr(jdir))
            endif
        end do
!
!        --- STOCKAGE ---
!
        call asstoc(mome, resu, nomsy, neq, zr(jdir),&
                    ndir, comdir, typcdi, glob, prim)
!
!        ---------------------------------------------------------------
!                            REPONSE SECONDAIRE
!        ---------------------------------------------------------------
        if (secon) then
!
!            --- PRISE EN COMPTE DES EFFETS D'ENTRAINEMENT ---
!            --- DANS LE CAS DE CALCUL DE REPONSE GLOBALE  ---
!
            if (nomsy(1:11) .ne. 'ACCE_ABSOLU') then
                call asecon(nomsy, neq, mome, resu)
            endif
!
        endif
!
        call jedetr(kvec)
        call jedetr(kval)
        call jedetr(kvx1)
        call jedetr(kvx2)
        call jedetr(kve2)
        call jedetr(kve3)
        call jedetr(kve4)
        call jedetr(kve5)
!
    end do
!
    call jedema()
end subroutine
