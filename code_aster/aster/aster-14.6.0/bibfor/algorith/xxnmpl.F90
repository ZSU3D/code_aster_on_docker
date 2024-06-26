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
! aslint: disable=W1306,W1504
! person_in_charge: samuel.geniaut at edf.fr
!
subroutine xxnmpl(elrefp, elrese, ndim, coorse, igeom,&
                  he, nfh, ddlc, ddlm, nfe,&
                  instam, instap, ideplp, sigm, vip,&
                  basloc, nnop, npg, typmod, option,&
                  imate, compor, lgpg, carcri, idepl,&
                  lsn, lst, idecpg, sig, vi,&
                  matuu, ivectu, codret, nfiss, heavn, jstno)
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/dfdm2d.h"
#include "asterfort/dfdm3d.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/indent.h"
#include "asterfort/lcegeo.h"
#include "asterfort/nmcomp.h"
#include "asterfort/r8inir.h"
#include "asterfort/reeref.h"
#include "asterfort/vecini.h"
#include "asterfort/xcinem.h"
#include "asterfort/xcalc_heav.h"
#include "asterfort/xcalc_code.h"
#include "asterfort/xcalfev_wrap.h"
#include "asterfort/xkamat.h"
#include "asterfort/iimatu.h"
#include "asterfort/xnbddl.h"
#include "asterfort/iselli.h"
#include "asterfort/Behaviour_type.h"
!
integer :: ndim, igeom, imate, lgpg, codret, nnop, npg
integer :: nfh, ddlc, ddlm, nfe, idepl, ivectu, ideplp
integer :: nfiss, heavn(nnop, 5), idecpg
integer :: jstno
character(len=8) :: elrefp, typmod(*)
character(len=8) :: elrese
character(len=16) :: option, compor(4)
real(kind=8) :: basloc(3*ndim*nnop), carcri(*), he(nfiss)
real(kind=8) :: lsn(nnop), lst(nnop), coorse(*)
real(kind=8) :: vi(lgpg, npg), vip(lgpg, npg), sig(2*ndim, npg), matuu(*)
real(kind=8) :: instam, instap, sigm(2*ndim, npg), sign(6)
!.......................................................................
!
!     BUT:  CALCUL  DES OPTIONS RIGI_MECA_TANG, RAPH_MECA ET FULL_MECA
!           EN HYPER-ELASTICITE AVEC X-FEM EN 2D ET EN 3D
!.......................................................................
!
! IN  ELREFP  : ÉLÉMENT DE RÉFÉRENCE PARENT
! IN  NDIM    : DIMENSION DE L'ESPACE
! IN  COORSE  : COORDONNÉES DES SOMMETS DU SOUS-ÉLÉMENT
! IN  IGEOM   : COORDONNÉES DES NOEUDS DE L'ÉLÉMENT PARENT
! IN  HE      : VALEUR DE LA FONCTION HEAVISIDE SUR LE SOUS-ÉLT
! IN  NFH     : NOMBRE DE FONCTIONS HEAVYSIDE
! IN  DDLC    : NOMBRE DE DDL DE CONTACT (PAR NOEUD)
! IN  DDLM    : NOMBRE DE DDL PAR NOEUD MILIEU (EN 2D)
! IN  NFE     : NOMBRE DE FONCTIONS SINGULIÈRES D'ENRICHISSEMENT
! IN  BASLOC  : BASE LOCALE AU FOND DE FISSURE AUX NOEUDS
! IN  NNOP    : NOMBRE DE NOEUDS DE L'ELEMENT PARENT
! IN  NPG     : NOMBRE DE POINTS DE GAUSS DU SOUS-ÉLÉMENT
! IN  TYPMOD  : TYPE DE MODELISATION
! IN  OPTION  : OPTION DE CALCUL
! IN  IMATE   : MATERIAU CODE
! IN  COMPOR  : COMPORTEMENT
! IN  LGPG    : "LONGUEUR" DES VARIABLES INTERNES POUR 1 POINT DE GAUSS
!               CETTE LONGUEUR EST UN MAJORANT DU NBRE REEL DE VAR. INT.
! IN  CRIT    : CRITERES DE CONVERGENCE LOCAUX
! IN  IDEPL   : ADRESSE DU DEPLACEMENT A PARTIR DE LA CONF DE REF
! IN  LSN     : VALEUR DE LA LEVEL SET NORMALE AUX NOEUDS PARENTS
! IN  LST     : VALEUR DE LA LEVEL SET TANGENTE AUX NOEUDS PARENTS
!
! OUT SIG     : CONTRAINTES DE CAUCHY (RAPH_MECA ET FULL_MECA)
! OUT VI      : VARIABLES INTERNES    (RAPH_MECA ET FULL_MECA)
! OUT MATUU   : MATRICE DE RIGIDITE PROFIL (RIGI_MECA_TANG ET FULL_MECA)
! OUT IVECTU  : VECTEUR FORCES NODALES (RAPH_MECA ET FULL_MECA)
!......................................................................
!
    integer :: i, ig, j, j1, kkd, kl, kpg, l, m, n, nn, mn
    integer :: ddls, ddld, cpt, idfde, ipoids, ivf, dec(nnop)
    integer :: jcoopg, jdfd2, jgano, ndimb, nno, nnops, nnos, npgbis, hea_se
    integer :: singu, alp, ii, jj, jvariext1, jvariext2
    real(kind=8) :: dsidep(6, 6), f(3, 3), eps(6), deps(6), sigma(6), ftf, detf
    real(kind=8) :: tmp1, tmp2, sigp(6)
    real(kind=8) :: xg(ndim), xe(ndim), ff(nnop), jac
    real(kind=8) :: rbid33(3, 3), rbid1(1)
    real(kind=8) :: dfdi(nnop, ndim), pff(6, nnop, nnop)
    real(kind=8) :: def(6, nnop, ndim*(1+nfh+nfe*ndim)), r
    real(kind=8) :: elgeom(10, 27)
    real(kind=8) :: fk(27,3,3), dkdgl(27,3,3,3), ka, mu
    aster_logical :: grdepl, axi, cplan
!
    integer :: indi(6), indj(6)
    real(kind=8) :: rind(6), rac2, angmas(3)
!
    data    indi / 1 , 2 , 3 , 1 , 1 , 2 /
    data    indj / 1 , 2 , 3 , 2 , 3 , 3 /
    data    rind / 0.5d0,0.5d0,0.5d0,0.70710678118655d0,&
     &               0.70710678118655d0,0.70710678118655d0 /
    data    rac2 / 1.4142135623731d0 /
    data    angmas /0.d0, 0.d0, 0.d0/
!--------------------------------------------------------------------
!     ATTENTION, EN 3D, ZR(IDEPL) ET ZR(VECTU) SONT DIMENSIONNÉS DE
!     TELLE SORTE QU'ILS NE PRENNENT PAS EN COMPTE LES DDL SUR LES
!     NOEUDS MILIEU
!
    elgeom(:,:) = 0.d0
!     NOMBRE DE DDL DE DEPLACEMENT À CHAQUE NOEUD
    call xnbddl(ndim, nfh, nfe, ddlc, ddld, ddls, singu)
!     RECUPERATION DU NOMBRE DE NOEUDS SOMMETS DE L'ELEMENT PARENT
    call elrefe_info(fami='RIGI', nnos=nnops)
!
! - INITIALISATION
    grdepl = .false.
    axi = typmod(1) .eq. 'AXIS'
    cplan = typmod(1) .eq. 'C_PLAN'
!
!
    call elrefe_info(elrefe=elrese, fami='XINT', ndim=ndimb, nno=nno, nnos=nnos,&
                     npg=npgbis, jpoids=ipoids, jcoopg=jcoopg, jvf=ivf, jdfde=idfde,&
                     jdfd2=jdfd2, jgano=jgano)
!
    ASSERT(npg.eq.npgbis.and.ndim.eq.ndimb)
!
! - Get coded integers for external state variables
!
    jvariext1 = nint(carcri(IVARIEXT1))
    jvariext2 = nint(carcri(IVARIEXT2))
!
! - Compute intrinsic external state variables
!
    call lcegeo(nno      , npg      , ndim     ,&
                ipoids   , ivf      , idfde    ,&
                typmod   , jvariext1, jvariext2,&
                zr(igeom))
!
    do n = 1, nnop
        call indent(n, ddls, ddlm, nnops, dec(n))
    end do
!
    hea_se=xcalc_code(nfiss, he_real=[he])
!-----------------------------------------------------------------------
! - CALCUL POUR CHAQUE POINT DE GAUSS
    do kpg = 1, npg
!
!       COORDONNÉES DU PT DE GAUSS DANS LE REPÈRE RÉEL : XG
        call vecini(ndim, 0.d0, xg)
        do i = 1, ndim
            do n = 1, nno
                xg(i) = xg(i) + zr(ivf-1+nno*(kpg-1)+n)*coorse(ndim*( n-1)+i)
            end do
        end do
!
!       COORDONNÉES DU POINT DE GAUSS DANS L'ÉLÉMENT DE RÉF PARENT : XE
!       ET CALCUL DE FF ET DFDI
        call reeref(elrefp, nnop, zr(igeom), xg, ndim,&
                    xe, ff, dfdi=dfdi)
!
!       FONCTION D'ENRICHISSEMENT AU POINT DE GAUSS ET LEURS DÉRIVÉES
        if (singu .gt. 0) then
            call xkamat(imate, ndim, axi, ka, mu)
            call xcalfev_wrap(ndim, nnop, basloc, zi(jstno), he(1),&
                         lsn, lst, zr(igeom), ka, mu, ff, fk, dfdi=dfdi, dkdgl=dkdgl)
        endif
!
! -     CALCUL DE LA DISTANCE A L'AXE (AXISYMETRIQUE)
!       ET DU DEPL. RADIAL
        if (axi) then
            r = 0.d0
            do n = 1, nnop
                r = r + ff(n)*zr(igeom-1+2*(n-1)+1)
            end do
!
            ASSERT(r.gt.0d0)
!          ATTENTION : LE POIDS N'EST PAS X R
!          CE SERA FAIT PLUS TARD AVEC JAC = JAC X R
        endif
!
! -     CALCUL DE DEPS
        call xcinem(axi, igeom, nnop, nnops, ideplp, grdepl,&
                    ndim, he,&
                    nfiss, nfh, singu, ddls, ddlm,&
                    fk, dkdgl, ff, dfdi, f,&
                    deps, rbid33, heavn)
!
! -     CALCUL DE EPS
        call xcinem(axi, igeom, nnop, nnops, idepl, grdepl,&
                    ndim, he,&
                    nfiss, nfh, singu, ddls, ddlm,&
                    fk, dkdgl, ff, dfdi, f,&
                    eps, rbid33, heavn)
!
! - CALCUL DES ELEMENTS GEOMETRIQUES
!
!       CALCUL DES PRODUITS SYMETR. DE F PAR N,
        def(:,:,:)=0.d0
        do n = 1, nnop
            cpt = 0
!         FONCTIONS DE FORME CLASSIQUES
            do i = 1, ndim
                cpt = cpt+1
                def(1,n,i) = f(i,1)*dfdi(n,1)
                def(2,n,i) = f(i,2)*dfdi(n,2)
                def(3,n,i) = 0.d0
                def(4,n,i) = (f(i,1)*dfdi(n,2) + f(i,2)*dfdi(n,1))/ rac2
                if (ndim .eq. 3) then
                    def(3,n,i) = f(i,3)*dfdi(n,3)
                    def(5,n,i) = (f(i,1)*dfdi(n,3) + f(i,3)*dfdi(n,1)) /rac2
                    def(6,n,i) = (f(i,2)*dfdi(n,3) + f(i,3)*dfdi(n,2)) /rac2
                endif
            end do
!
!       TERME DE CORRECTION (3,3) AXI QUI PORTE EN FAIT SUR LE DDL 1
            if (axi) then
                def(3,n,1) = f(3,3) * ff(n)/r
            endif
!
!         ENRICHISSEMENT PAR HEAVYSIDE
            do ig = 1, nfh
                do i = 1, ndim
                    cpt = cpt+1
                    do m = 1, 2*ndim
                        def(m,n,cpt) = def(m,n,i) * xcalc_heav(heavn(n,ig),hea_se,heavn(n,5))
                    end do
                    if (ndim .eq. 2) then
                        def(3,n,cpt) = 0.d0
                    endif
                end do
!
!  ATTENTION:TERME DE CORRECTION (3,3) AXI SUR LE DDL 1+NDIM*IG
                if (axi) then
                    def(3,n,(1+ndim*ig)) = f(3,3)*ff(n)/r*xcalc_heav(heavn(n,ig),hea_se,heavn(n,5))
                endif
!
            end do
!         ENRICHISSEMENT PAR LES NFE FONTIONS SINGULIÈRES
            do ig = 1, singu
              do alp = 1, ndim
                do i = 1, ndim
                    cpt=cpt+1
                    def(1,n,cpt) = f(i,1)* dkdgl(n,alp,i,1)
!
                    def(2,n,cpt) = f(i,2)* dkdgl(n,alp,i,2)
!
                    def(3,n,cpt) = 0.d0
!
                    def(4,n,cpt) = (&
                                   f(i,1)* dkdgl(n,alp,i,2) + f(i,2)* dkdgl(n,alp,i,1)&
                                   )/rac2
!
                    if (ndim .eq. 3) then
                        def(3,n,cpt) = f(i,3)* dkdgl(n,alp,i,3)
                        def(5,n,cpt) = (&
                                       f(i,1)* dkdgl(n,alp,i,3) + f(i,3)* dkdgl(n,alp,i,1)&
                                       )/rac2
                        def(6,n,cpt) = (&
                                       f(i,3)* dkdgl(n,alp,i,2) + f(i,2)* dkdgl(n,alp,i,3)&
                                       )/rac2
                    endif
                end do
!
              end do
!
!   TERME DE CORRECTION (3,3) AXI PORTE SUR LE DDL 1+NDIM*(NFH+ALP)
!      EN AXI: ON PROJETTE L ENRICHISSEMENT VECTORIEL SUIVANT X
                if (axi) then
                  do alp = 1, ndim
                    def(3,n,(1+ndim*(nfh+alp))) = f(3,3)* fk(n,alp,1)/r
                  end do
                endif
!
            end do
!
            ASSERT(cpt.eq.ddld)
!
        end do
!
!       POUR CALCULER LE JACOBIEN DE LA TRANSFO SSTET->SSTET REF
!       ON ENVOIE DFDM2D OU DFDM3D AVEC LES COORD DU SS-ELT
        if (ndim .eq. 2) then
            call dfdm2d(nno, kpg, ipoids, idfde, coorse,&
                        jac)
        else if (ndim.eq.3) then
            call dfdm3d(nno, kpg, ipoids, idfde, coorse,&
                        jac)
        endif
!
        if (axi) then
            jac= jac * r
        endif
!
!      CALCUL DES PRODUITS DE FONCTIONS DE FORMES (ET DERIVEES)
        if (( option(1:10) .eq. 'RIGI_MECA_' .or. option(1: 9) .eq. 'FULL_MECA' ) .and.&
            grdepl) then
            do n = 1, nnop
                do m = 1, n
                    pff(1,n,m) = dfdi(n,1)*dfdi(m,1)
                    pff(2,n,m) = dfdi(n,2)*dfdi(m,2)
                    pff(3,n,m) = 0.d0
                    pff(4,n,m) =(dfdi(n,1)*dfdi(m,2)+dfdi(n,2)*dfdi(m,&
                    1))/rac2
                    if (ndim .eq. 3) then
                        pff(3,n,m)= dfdi(n,3)*dfdi(m,3)
                        pff(5,n,m)=(dfdi(n,1)*dfdi(m,3)+dfdi(n,3)*&
                        dfdi(m,1))/rac2
                        pff(6,n,m)=(dfdi(n,2)*dfdi(m,3)+dfdi(n,3)*&
                        dfdi(m,2))/rac2
                    endif
                end do
            end do
        endif
!
!
! - LOI DE COMPORTEMENT : S(E) ET DS/DE
!
!      CALL NMCPEL('RIGI',KPG,1,POUM,NDIM,TYPMOD,ANGMAS,IMATE,COMPOR,
!   &               CRIT,OPTION,EPS,SIGMA,VI(1,KPG),DSIDEP,CODRET)
!
        do m = 1, 3
            sign(m) = sigm(m,kpg)
        end do
        do m = 4, 2*ndim
            sign(m) = sigm(m,kpg)*rac2
        end do
!
        call r8inir(6, 0.0d0, sigma, 1)
        call nmcomp('XFEM', idecpg+kpg, 1, ndim, typmod,&
                    imate, compor, carcri, instam, instap,&
                    6, eps, deps, 6, sign,&
                    vi(1, kpg), option, angmas, 10, elgeom(1, kpg),&
                    sigma, vip(1, kpg), 36, dsidep, 1,&
                    rbid1, codret)
!
! - CALCUL DE LA MATRICE DE RIGIDITE
!
        if (option(1:10) .eq. 'RIGI_MECA_' .or. option(1: 9) .eq. 'FULL_MECA') then
!
            do n = 1, nnop
                nn=dec(n)
!
                do i = 1, ddld
                    ii=iimatu(i,ndim,nfh,nfe)
                    kkd = (nn+ii-1) * (nn+ii) /2
                    do kl = 1, 2*ndim
                        sigp(kl) = 0.d0
                        do l = 1, 2*ndim
                            sigp(kl) = sigp(kl)+def(l,n,i)*dsidep(l, kl)
                        end do
                    end do
                    do j = 1, ddld
                        jj=iimatu(j,ndim,nfh,nfe)
                        do m = 1, n
                            mn=dec(m)
!
                            if (m .eq. n) then
                                j1 = ii
                            else
                                j1 = ddld
                            endif
!
!                 RIGIDITE GEOMETRIQUE
                            tmp1 = 0.d0
                            if (grdepl .and. ii .eq. jj) then
                                tmp1 = 0.d0
                                do l = 1, 2*ndim
                                    tmp1 = tmp1+pff(l,n,m)*sigma(l)
                                end do
!
!                  TERME DE CORRECTION AXISYMETRIQUE
!                    IF (AXI .AND. I.EQ.1) THEN
!                      TMP1 = TMP1+ZR(IVF+N+(KPG-1)*NNO-1)*
!     &                           ZR(IVF+M+(KPG-1)*NNO-1)/(R*R)*SIGMA(3)
!                    ENDIF
                            endif
!
!                 RIGIDITE ELASTIQUE
                            tmp2=0.d0
                            do l = 1, 2*ndim
                                tmp2=tmp2+sigp(l)*def(l,m,j)
                            end do
!
!                 STOCKAGE EN TENANT COMPTE DE LA SYMETRIE
                            if (jj .le. j1) then
                                matuu(kkd+mn+jj) = matuu(kkd+mn+jj) + ( tmp1+tmp2)*jac
                            endif
!
                        end do
                    end do
                end do
            end do
        endif
!
!
! - CALCUL DE LA FORCE INTERIEURE ET DES CONTRAINTES DE CAUCHY
!
        if (option(1:9) .eq. 'FULL_MECA' .or. option(1:9) .eq. 'RAPH_MECA') then
!
            do n = 1, nnop
                nn=dec(n)
!
                do i = 1, ddld
                    ii=iimatu(i,ndim,nfh,nfe)
                    do l = 1, 2*ndim
                        zr(ivectu-1+nn+ii)= zr(ivectu-1+nn+ii) + def(l,&
                        n,i)*sigma(l)*jac
                    end do
                end do
            end do
!
            if (grdepl) then
!           CONVERSION LAGRANGE -> CAUCHY
                if (cplan) f(3,3) = sqrt(abs(2.d0*eps(3)+1.d0))
                detf = f(3,3) * (f(1,1)*f(2,2)-f(1,2)*f(2,1))
                if (ndim .eq. 3) then
                    detf = detf - f(2,3)*(f(1,1)*f(3,2)-f(3,1)*f(1,2)) + f(1,3)*(f(2,1)*f(3,2)-f(&
                           &3,1)*f(2,2))
                endif
                do i = 1, 2*ndim
                    sig(i,kpg) = 0.d0
                    do l = 1, 2*ndim
                        ftf = (&
                              f(&
                              indi(i), indi(l))*f(indj(i), indj(l)) + f(indi(i),&
                              indj(l))*f(indj(i), indi(l))&
                              )*rind(l&
                              )
                        sig(i,kpg) = sig(i,kpg) + ftf*sigma(l)
                    end do
                    sig(i,kpg) = sig(i,kpg)/detf
                end do
            else
!           SIMPLE CORRECTION DES CONTRAINTES
                do l = 1, 3
                    sig(l,kpg) = sigma(l)
                end do
                do l = 4, 2*ndim
                    sig(l,kpg) = sigma(l)/rac2
                end do
            endif
        endif
!
    end do
!
end subroutine
