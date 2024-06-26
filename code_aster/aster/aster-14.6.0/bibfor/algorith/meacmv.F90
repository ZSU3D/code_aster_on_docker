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

subroutine meacmv(modele, mate, carele, fomult, lischa,&
                  partps, numedd, assmat, solveu, vecass,&
                  matass, maprec, cnchci, base, compor)
!
!
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/asasve.h"
#include "asterfort/ascavc.h"
#include "asterfort/ascova.h"
#include "asterfort/asmatr.h"
#include "asterfort/detrsd.h"
#include "asterfort/fetccn.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveuo.h"
#include "asterfort/merime.h"
#include "asterfort/nmvcd2.h"
#include "asterfort/nmvcex.h"
#include "asterfort/nmvcle.h"
#include "asterfort/preres.h"
#include "asterfort/uttcpu.h"
#include "asterfort/vechme.h"
#include "asterfort/vectme.h"
#include "asterfort/vecvme.h"
#include "asterfort/vedime.h"
#include "asterfort/velame.h"
#include "asterfort/vrcref.h"
    aster_logical :: assmat
    character(len=1) :: base
    character(len=19) :: lischa, solveu, vecass, matass, maprec
    character(len=24) :: cnchci, modele, carele, fomult, numedd, compor
    character(len=*) :: mate
    real(kind=8) :: partps(3)
!
! ----------------------------------------------------------------------
!     MECANIQUE STATIQUE - ACTUALISATION DES CHARGEMENTS MECANIQUES
!     **                   *                 *           *
! ----------------------------------------------------------------------
! IN  MODELE  : NOM DU MODELE
! IN  MATE    : NOM DU MATERIAU
! IN  CARELE  : NOM D'1 CARAC_ELEM
! IN  FOMULT  : LISTE DES FONCTIONS MULTIPLICATRICES
! IN  LISCHA  : INFORMATION SUR LES CHARGEMENTS
! IN  PARTPS  : PARAMETRES TEMPORELS
! IN  NUMEDD  : PROFIL DE LA MATRICE
! IN  ASSMAT  : BOOLEEN POUR LE CALCUL DE LA MATRICE
! IN  SOLVEU  : METHODE DE RESOLUTION 'LDLT' OU 'GCPC'
! OUT VECASS  : VECTEUR ASSEMBLE SECOND MEMBRE
! OUT MATASS,MAPREC  MATRICE DE RIGIDITE ASSEMBLEE
! OUT CNCHCI  : OBJET DE S.D. CHAM_NO DIMENSIONNE A LA TAILLE DU
!               PROBLEME, VALANT 0 PARTOUT, SAUF LA OU LES DDLS IMPOSES
!               SONT TRAITES PAR ELIMINATION (= DEPLACEMENT IMPOSE)
! IN  BASE    : BASE DE TRAVAIL
! IN/OUT  MAPREC  : MATRICE PRECONDITIONNEE
! IN  COMPOR  : COMPOR POUR LES MULTIFIBRE (POU_D_EM)
!----------------------------------------------------------------------
!
!
!
! 0.2. ==> COMMUNS
!
!
! 0.3. ==> VARIABLES LOCALES
!
    character(len=6) :: nompro
    parameter ( nompro = 'MEACMV' )
!
    integer :: jchar, jinf, nh, ierr, jtp, ibid
    integer :: nchar, typcum
    real(kind=8) :: time
    character(len=1) :: typres
    character(len=8) :: matele
    character(len=14) :: com
    character(len=19) :: chvref, chvarc
    character(len=16) :: option
    character(len=19) :: chamn1, chamn2, chamn3, chamn4
    character(len=24) :: k24bid, blan24, vediri, vadiri, velapl, valapl, vecham
    character(len=24) :: vacham, chlapl, chdiri, chcham, chths, charge, infoch
    character(len=24) :: vecths
    aster_logical :: ass1er, lhydr, lsech, ltemp, lptot
!
! DEB-------------------------------------------------------------------
!====
! 1. PREALABLES
!====
!
    call jemarq()
!
! 1.2. ==> NOM DES STRUCTURES
!
! 1.2.1. ==> FIXES
!
!               12   345678   9012345678901234
    com = '&&'//nompro//'.COM__'
    chvarc = '&&'//nompro//'.CHVRC'
!     -- POUR NE CREER Q'UN SEUL CHAMP DE VARIABLES DE REFERENCE
    chvref = modele(1:8)//'.CHVCREF'
!
!               12345678
    matele = '&&MATELE'
!
!
    blan24 = ' '
    k24bid = blan24
    lhydr=.false.
    lsech=.false.
    lptot=.false.
    chths = blan24
!
! 1.2. ==> LES CONSTANTES
!
    time = partps(1)
!
    charge = lischa//'.LCHA'
!
    call nmvcle(modele, mate, carele, time, com)
    call vrcref(modele(1:8), mate(1:8), carele(1:8), chvref)
    call nmvcex('TOUT', com, chvarc)
    call nmvcd2('HYDR', mate, lhydr)
    call nmvcd2('PTOT', mate, lptot)
    call nmvcd2('SECH', mate, lsech)
    call nmvcd2('TEMP', mate, ltemp)
!
    call jeveuo(charge, 'L', jchar)
    infoch = lischa//'.INFC'
    call jeveuo(infoch, 'L', jinf)
    nchar = zi(jinf)
!
    nh = 0
!
    typres = 'R'
!
    ass1er = .false.
!
!
!
!====
! 2. LE PREMIER MEMBRE
!====
!
! 2.1. ==> CALCULS ELEMENTAIRES DU 1ER MEMBRE:
!
    if (assmat) then
!
        call uttcpu('CPU.OP0046.1', 'DEBUT', ' ')
        call merime(modele(1:8), nchar, zk24(jchar), mate, carele(1:8),&
                    time, compor, matele, nh,&
                    base)
        ass1er = .true.
        call uttcpu('CPU.OP0046.1', 'FIN', ' ')
!
    endif
!
! 2.2. ==> ASSEMBLAGE
!
    if (ass1er) then
!
        call uttcpu('CPU.OP0046.2', 'DEBUT', ' ')
        call asmatr(1, matele, ' ', numedd, &
                    lischa, 'ZERO', 'V', 1, matass)
        call detrsd('MATR_ELEM', matele)
!
! 2.3. ==> DECOMPOSITION OU CALCUL DE LA MATRICE DE PRECONDITIONEMENT
!
        call preres(solveu, 'V', ierr, maprec, matass,&
                    ibid, -9999)
!
!
        ass1er = .false.
        call uttcpu('CPU.OP0046.2', 'FIN', ' ')
!
    endif
!
!====
! 3. LES CHARGEMENTS
!====
!
    call uttcpu('CPU.OP0046.3', 'DEBUT', ' ')
!
! 3.1. ==> LES DIRICHLETS
!
    vadiri = blan24
    vediri = blan24
    chdiri = blan24
    call vedime(modele, charge, infoch, time, typres,&
                vediri)
    call asasve(vediri, numedd, typres, vadiri)
    call ascova('D', vadiri, fomult, 'INST', time,&
                typres, chdiri)
!
! 3.2. ==> CAS DU CHARGEMENT TEMPERATURE, HYDRATATION, SECHAGE,
!          PRESSION TOTALE (CHAINAGE HM)
!
    if (ltemp .or. lhydr .or. lsech .or. lptot) then
        vecths = blan24
        if (ltemp) then
            call vectme(modele, carele, mate, compor, com,&
                        vecths)
            call asasve(vecths, numedd, typres, chths)
        endif
        if (lhydr) then
            option = 'CHAR_MECA_HYDR_R'
            call vecvme(option, modele, carele, mate, compor,&
                        com, numedd, chths)
        endif
        if (lptot) then
            option = 'CHAR_MECA_PTOT_R'
            call vecvme(option, modele, carele, mate, compor,&
                        com, numedd, chths)
        endif
        if (lsech) then
            option = 'CHAR_MECA_SECH_R'
            call vecvme(option, modele, carele, mate, compor,&
                        com, numedd, chths)
        endif
!
        call jeveuo(chths, 'L', jtp)
        chths=zk24(jtp)(1:19)
    endif
!
! 3.3. ==> FORCES DE LAPLACE
!
    valapl = blan24
    velapl = blan24
    chlapl = blan24
    k24bid = blan24
    call velame(modele, charge, infoch, k24bid, velapl)
    call asasve(velapl, numedd, typres, valapl)
    call ascova('D', valapl, fomult, 'INST', time,&
                typres, chlapl)
!
! 3.4. ==> AUTRES CHARGEMENTS
!
    vacham = blan24
    vecham = blan24
    chcham = blan24
    k24bid = blan24
!
    call vechme('S', modele, charge, infoch, partps,&
                carele, mate, vecham, varc_currz = chvarc)
    call asasve(vecham, numedd, typres, vacham)
    call ascova('D', vacham, fomult, 'INST', time,&
                typres, chcham)
!
! 3.6. ==> SECOND MEMBRE DEFINITIF : VECASS
!
    typcum = 3
    chamn1 = chdiri(1:19)
    chamn2 = chcham(1:19)
    chamn3 = chlapl(1:19)
    if (chths(1:19) .ne. ' ') then
        typcum = 4
        chamn4 = chths(1:19)
    endif
!
! 3.6.2. ==> CONCATENATION DES SECOND(S) MEMBRE(S)
!
    call fetccn(chamn1, chamn2, chamn3, chamn4, typcum,&
                vecass)
!
!
! 3.7. ==> CHARGES CINEMATIQUES
!
    cnchci = blan24
    call ascavc(charge, infoch, fomult, numedd, time,&
                cnchci)
!
!====
! 4. DESTRUCTION DES CHAMPS TEMPORAIRES
!====
!
    call detrsd('VECT_ELEM', vediri(1:19))
    call detrsd('CHAMP_GD', chdiri(1:19))
    call detrsd('VECT_ELEM', velapl(1:19))
    call detrsd('CHAMP_GD', chlapl(1:19))
    call detrsd('VECT_ELEM', vecham(1:19))
    call detrsd('CHAMP_GD', chcham(1:19))
    if (ltemp) then
        call detrsd('VECT_ELEM', vecths(1:19))
        call detrsd('CHAMP_GD', chths(1:19))
    endif
!
    call jedema()
end subroutine
