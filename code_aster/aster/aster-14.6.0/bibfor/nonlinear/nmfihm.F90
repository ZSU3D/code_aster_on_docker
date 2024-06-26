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

subroutine nmfihm(ndim, nddl, nno1, nno2, npg,&
                  lgpg, ipg, wref, vff1, vff2,&
                  idf2, dffr2, mate, option, geom,&
                  ddlm, ddld, iu, ip, sigm,&
                  sigp, vect, matr, vim, vip,&
                  tm, tp, crit, compor, typmod)
!
! person_in_charge: jerome.laverne at edf.fr
!
! aslint: disable=W1306,W1504
    implicit none
#include "asterf_types.h"
#include "asterfort/ejcine.h"
#include "asterfort/gedisc.h"
#include "asterfort/nmcomp.h"
#include "asterfort/r8inir.h"
#include "asterfort/utmess.h"
    integer :: ndim, mate, npg, ipg, idf2, lgpg, nno1, nno2, nddl, iu(3, 16)
    integer :: ip(8)
    real(kind=8) :: vff1(nno1, npg), vff2(nno2, npg), dffr2(ndim-1, nno2, npg)
    real(kind=8) :: wref(npg), geom(ndim, nno2), ddlm(nddl), ddld(nddl), tm, tp
    real(kind=8) :: sigm(2*ndim-1, npg), sigp(2*ndim-1, npg)
    real(kind=8) :: vect(nddl), matr(nddl*nddl)
    real(kind=8) :: vim(lgpg, npg), vip(lgpg, npg)
    character(len=8) :: typmod(*)
    character(len=16) :: option, compor(*)
!-----------------------------------------------------------------------
!  OPTIONS DE MECANIQUE NON LINEAIRE POUR JOINT ET JOINT_HYME 2D ET 3D
!
!    OPTIONS DE CALCUL
!       * RAPH_MECA      : DDL = DDL- + DDDL  ->   SIGP , FINT
!       * FULL_MECA      : DDL = DDL- + DDDL  ->   SIGP , FINT , KTAN
!       * RIGI_MECA_TANG : DDL = DDL-       ->                  KTAN
!-----------------------------------------------------------------------
! IN  NDIM   DIMENSION DE L'ESPACE
! IN  NDDL   NOMBRE DE DEGRES DE LIBERTE TOTAL
! IN  NNO1   NOMBRE DE NOEUDS DE LA FACE POUR LES DEPLACEMENTS
! IN  NNO2   NOMBRE DE NOEUDS DE LA FACE POUR LES PRESSIONS ET LA GEOM
! IN  NPG    NOMBRE DE POINTS DE GAUSS
! IN  LGPG   NOMBRE DE VARIABLES INTERNES
! IN  WREF   POIDS DE REFERENCE DES POINTS DE GAUSS
! IN  VFF1   VALEUR DES FONCTIONS DE FORME (DE LA FACE) POUR U
! IN  VFF2   VALEUR DES FONCTIONS DE FORME (DE LA FACE) POUR P ET X
! IN  DFFR2  DERIVEE DES FONCTIONS DE FORME DE REFERENCE DE P ET X EN G
! IN  MATE   MATERIAU CODE
! IN  OPTION OPTION DE CALCUL
! IN  GEOM   COORDONNEES NOEUDS DE PRESSION (2D:SEG2,3D:TRIA3 OU QUAD4)
! IN  DDLM   VALEURS DES DEGRES DE LIBERTE A L'INSTANT MOINS
! IN  DDLD   VALEURS DES INCREMEMNT DES DEGRES DE LIBERTE
! IN  IU     DECALAGE D'INDICE POUR ACCEDER AUX DDL DE DEPLACEMENT
! IN  IP     DECALAGE D'INDICE POUR ACCEDER AUX DDL DE PRESSION
! IN  SIGM   CONTRAINTES -         (RAPH_MECA   ET FULL_MECA_*)
! IN  VIM    VARIABLES INTERNES AU DEBUT DU PAS DE TEMPS
! IN  TM     INSTANT -
! IN  TP     INSTANT +
! IN  CRIT   VALEURS DE L'UTILISATEUR POUR LES CRITERES DE CONVERGENCE
! IN  COMPOR NOM DE LA LOI DE COMPORTEMENT
! IN  TYPMOD TYPE DE LA MODELISATION
!
! OUT SIGP    : CONTRAINTES +         (RAPH_MECA   ET FULL_MECA_*)
! OUT VIP     : VARIABLES INTERNES    (RAPH_MECA   ET FULL_MECA_*)
! OUT MATR    : MATRICE DE RIGIDITE   (RIGI_MECA_* ET FULL_MECA_*)
! OUT VECT    : FORCES INTERIEURES    (RAPH_MECA   ET FULL_MECA_*)
!-----------------------------------------------------------------------
!
    aster_logical :: resi, rigi, axi, ifhyme
    integer :: i, j, kk, m, n, os, p, q, ibid, kpg, ncooro
    real(kind=8) :: dsidep(6, 6), b(2*ndim-1, ndim+1, 2*nno1+nno2)
    real(kind=8) :: sigmo(6), sigma(6), epsm(6), deps(6), wg
    real(kind=8) :: coopg(ndim+1, npg), rot(ndim*ndim)
    real(kind=8) :: coorot(ndim+ndim*ndim, npg)
    real(kind=8) :: crit(*), rbid(1), presgm, presgd, temp
!
    axi = .false.
    resi = option.eq.'RAPH_MECA' .or. option(1:9).eq.'FULL_MECA'
    rigi = option(1:9).eq.'FULL_MECA'.or.option(1:10).eq.'RIGI_MECA_'
!
! IFHYME = TRUE  : CALCUL COUPLE HYDRO-MECA
! IFHYME = FALSE : CALCUL MECA SANS HYDRO ET ELIMINATION DES DDL DE PRES
! (FINT_P=0, KTAN_PP=IDENTITE, KTAN_UP=0)
    if (typmod(2) .eq. 'EJ_HYME') ifhyme=.true.
    if (typmod(2) .eq. 'ELEMJOIN') ifhyme=.false.
!
    if (.not. resi .and. .not. rigi) then
        call utmess('F', 'ALGORITH7_61', sk=option)
    endif
!
!     INITIALISATIONS :
    if (resi) call r8inir(nddl, 0.d0, vect, 1)
    if (rigi) call r8inir(nddl*nddl, 0.d0, matr, 1)
!
!     CALCUL DES COORDONNEES DES POINTS DE GAUSS
    call gedisc(ndim, nno2, npg, vff2, geom,&
                coopg)
!
!     BOUCLE SUR LES PG
    do 11 kpg = 1, npg
!
!       CALCUL DE LA MATRICE CINEMATIQUE
        call ejcine(ndim, axi, nno1, nno2, vff1(1, kpg),&
                    vff2(1, kpg), wref(kpg), dffr2(1, 1, kpg), geom, wg,&
                    kpg, ipg, idf2, rot, b)
!
!       CALCUL DES DEFORMATIONS (SAUTS ET GRADIENTS DE PRESSION)
        call r8inir(6, 0.d0, epsm, 1)
        call r8inir(6, 0.d0, deps, 1)
!
        do 150 i = 1, ndim
            do 160 j = 1, ndim
                do n = 1, 2*nno1
                    epsm(i) = epsm(i) + b(i,j,n)*ddlm(iu(j,n))
                    deps(i) = deps(i) + b(i,j,n)*ddld(iu(j,n))
                enddo
160         continue
150     continue
!
        do 151 i = ndim+1, 2*ndim-1
            do n = 1, nno2
                epsm(i) = epsm(i) + b(i,ndim+1,2*nno1+n)*ddlm(ip(n))
                deps(i) = deps(i) + b(i,ndim+1,2*nno1+n)*ddld(ip(n))
            enddo
151     continue
!
!       CALCUL DE LA PRESSION AU POINT DE GAUSS
        presgm = 0.d0
        presgd = 0.d0
        do n = 1, nno2
            presgm = presgm + ddlm(ip(n))*vff2(n,kpg)
            presgd = presgd + ddld(ip(n))*vff2(n,kpg)
        enddo
!
!       STOCKAGE DE LA PRESSION DE FLUIDE AU PG
!       POUR LA VI DE POST-TRAITEMENT DANS LA LDC
        epsm(2*ndim) = presgm
        deps(2*ndim) = presgd
!
!       COOROT : COORDONNEES DU PG + MATRICE DE ROTATION
!       (MATRICE UTILE POUR LES VI DE POST-TRAITEMENT DANS LA LDC)
        do j = 1, ndim
            coorot(j,kpg)=coopg(j,kpg)
        enddo
        do j = 1, ndim*ndim
            coorot(ndim+j,kpg)=rot(j)
        enddo
        ncooro=ndim+ndim*ndim
!
!       CONTRAINTES -
        call r8inir(6, 0.d0, sigmo, 1)
        do n = 1, 2*ndim-1
            sigmo(n) = sigm(n,kpg)
        enddo
!
! - APPEL A LA LOI DE COMPORTEMENT
        call nmcomp('RIGI', kpg, 1, ndim, typmod,&
                    mate, compor, crit, tm, tp,&
                    6, epsm, deps, 6, sigmo,&
                    vim(1, kpg), option, rbid, ncooro, coorot(1, kpg),&
                    sigma, vip(1, kpg), 36, dsidep, 1,&
                    rbid, ibid)
!
! - CONTRAINTE ET EFFORTS INTERIEURS
!
        if (resi) then
!
!         CONTRAINTES +
            do n = 1, 2*ndim-1
                sigp(n,kpg) = sigma(n)
            enddo
!
!         VECTEUR FINT : U
            do 300 n = 1, 2*nno1
                do 301 i = 1, ndim
!
                    kk = iu(i,n)
                    temp = 0.d0
                    do j = 1, ndim
                        temp = temp + b(j,i,n)*sigp(j,kpg)
                    enddo
!
                    vect(kk) = vect(kk) + wg*temp
!
301             continue
300         continue
!
!         VECTEUR FINT : P
            do 302 n = 1, nno2
!
                kk = ip(n)
                temp = 0.d0
                do i = ndim+1, 2*ndim-1
                    temp = temp + b(i,ndim+1,2*nno1+n)*sigp(i,kpg)
                enddo
                if (ifhyme) then
                    vect(kk) = vect(kk) + wg*temp
                else
!             SI IFHYME=FALSE => FINT_P=0
                    vect(kk) = 0.d0
                endif
!
302         continue
!
        endif
!
! - MATRICE TANGENTE
!
        if (rigi) then
!
!         MATRICE K:U(I,N),U(J,M)
            do 500 n = 1, 2*nno1
                do 501 i = 1, ndim
!
                    os = (iu(i,n)-1)*nddl
!
                    do 520 m = 1, 2*nno1
                        do 521 j = 1, ndim
!
                            kk = os + iu(j,m)
                            temp = 0.d0
!
                            do 540 p = 1, ndim
                                do q = 1, ndim
                                    temp = temp + b(p,i,n)*dsidep(p,q) *b(q,j,m)
                                enddo
540                         continue
!
                            matr(kk) = matr(kk) + wg*temp
!
521                     continue
520                 continue
!
501             continue
500         continue
!
!         MATRICE K:P(N),P(M)
            do 502 n = 1, nno2
!
                os = (ip(n)-1)*nddl
!
                do 522 m = 1, nno2
!
                    kk = os + ip(m)
                    temp = 0.d0
!
                    do 542 p = ndim+1, 2*ndim-1
                        do q = ndim+1, 2*ndim-1
                            temp = temp + b(p,ndim+1,2*nno1+n)*dsidep( p,q) *b(q,ndim+1,2*nno1+m)
                        enddo
542                 continue
                    if (ifhyme) then
                        matr(kk) = matr(kk) + wg*temp
                    else
!               SI IFHYME=FALSE => K_PP=IDENTITE
                        if (n .eq. m) then
                            matr(kk) = 1.d0
                        else
                            matr(kk) = 0.d0
                        endif
                    endif
!
522             continue
502         continue
!
!         MATRICE K:P(N),U(J,M)
!         ATTENTION, TERME MIS A ZERO, VERIFICATION NECESSAIRE
            do 503 n = 1, nno2
!
                os = (ip(n)-1)*nddl
!
                do 523 m = 1, 2*nno1
                    do 533 j = 1, ndim
!
                        kk = os + iu(j,m)
                        temp = 0.d0
!
                        do 543 p = ndim+1, 2*ndim-1
                            do q = 1, ndim
!                               A ANNULE AFIN DE PASSER VERS LA MINIMISATION ALTERNEE
                                temp = temp + b(p,ndim+1,2*nno1+n) *dsidep(p,q)*b(q,j,m)
                            enddo
543                      continue
!
                        if (ifhyme) then
                            matr(kk) = matr(kk) + wg*temp
                        else
!               SI IFHYME=FALSE => K_PU=0.
                            matr(kk)=0.d0
                        endif
!
533                 continue
523             continue
503         continue
!
!         MATRICE K:U(I,N),P(M)
            do 504 n = 1, 2*nno1
                do 514 i = 1, ndim
!
                    os = (iu(i,n)-1)*nddl
!
                    do m = 1, nno2
!
                        kk = os + ip(m)
                        temp = -b(1,i,n)*vff2(m,kpg)
!
                        if (ifhyme) then
                            matr(kk) = matr(kk) + wg*temp
                        else
!               SI IFHYME=FALSE => K_UP=0.
                            matr(kk)=0.d0
                        endif
!
                    enddo
!
514             continue
504         continue
!
        endif
!
11  continue
!
end subroutine
