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

subroutine nmelnl(fami, kpg, ksp, poum,&
                  ndim, typmod, imate, compor, crit,&
                  option, eps, sig, vi, dsidep,&
                  energi)
!
!     REALISE LA LOI DE HENCKY POUR LES ELEMENTS ISOPARAMETRIQUES
!
! IN  NDIM    : DIMENSION DE L'ESPACE
! IN  TYPMOD  : TYPE DE MODELISATION
! IN  IMATE   : NATURE DU MATERIAU
! IN  COMPOR  : COMPORTEMENT
! IN  CRIT    : CRITERES DE CONVERGENCE LOCAUX
! IN  TEMP    : TEMPERATURE.
! IN  TREF    : TEMPERATURE DE REFERENCE.
! IN  EPS     : DEFORMATION (SI C_PLAN EPS(3) EST EN FAIT CALCULE)
! IN  OPTION  : OPTION DEMANDEE : RIGI_MECA_TANG -> SIG    DSIDEP
!                                 FULL_MECA      -> SIG VI DSIDEP
!                                 RAPH_MECA      -> SIG VI
!                                 RUPTURE        -> SIG VI ENERGI
! OUT SIG    : CONTRAINTES LAGRANGIENNES
! OUT VI     : VARIABLE INTERNE (AUXILIAIRE DE CALCUL)
! OUT DSIDEP : MATRICE CARREE
! OUT ENERGI(1)  : ENERGIE LIBRE (POUR LE CALCUL DE G)
! OUT ENERGI(2)  : DERIVEE DE L'ENERGIE LIBRE / TEMPERATURE
! ----------------------------------------------------------------------
! CORPS DU PROGRAMME
! aslint: disable=
    implicit none
!
! DECLARATION PARAMETRES D'APPELS
#include "asterf_types.h"
#include "asterc/r8prem.h"
#include "asterfort/ecpuis.h"
#include "asterfort/nmcri1.h"
#include "asterfort/nmcri2.h"
#include "asterfort/nmelru.h"
#include "asterfort/rcfonc.h"
#include "asterfort/rctrac.h"
#include "asterfort/rcvala.h"
#include "asterfort/rcvalb.h"
#include "asterfort/rcvarc.h"
#include "asterfort/utmess.h"
#include "asterfort/verift.h"
#include "asterfort/zerofr.h"
    integer :: kpg, ksp, ndim, imate, iret, isec, ihyd
    character(len=*) :: fami, poum
    character(len=8) :: typmod(*)
    character(len=16) :: compor(*), option
    real(kind=8) :: crit(*), temp, ptot, hydr, sech
    real(kind=8) :: secref
    real(kind=8) :: eps(6), sig(6), vi, dsidep(6, 6), energi(2)
!
! DECLARATION VARIABLES LOCALES
    aster_logical :: cplan, elas, vmis, line, nonlin, inco, puis
    integer :: icodre(5)
    character(len=16) :: nomres(5)
    character(len=32) :: phenom
    integer :: jprol, jvale, nbvale, ndimsi, niter, k, l, ibid
!
    real(kind=8) :: valres(5), e, nu, troisk, deuxmu, sigy, dsde
    real(kind=8) :: kdess, bendo, ther, epsth(6), epsmo, epsdv(6), epseq, sieleq
    real(kind=8) :: p, rp, rprim, g, coef, epsi, airerp
    real(kind=8) :: approx, prec, x, kron(6), divu, biot
    real(kind=8) :: coco, dp0, rprim0, xap, precr
!
!====================================================================
!---COMMONS NECESSAIRES A HENCKY C_PLAN (NMCRI1)
!====================================================================
    integer :: imate2, jprol2, jvale2, nbval2
    real(kind=8) :: pm, sigel(6), lin, epsthe, epspto
    common /rconm1/ deuxmu, nu, e, sigy, rprim, pm, sigel, lin
    common /kconm1/ imate2, jprol2, jvale2, nbval2
!====================================================================
!---COMMONS NECESSAIRES A ELAS_VMIS_PUIS
!====================================================================
    common /rconm2/alfafa,unsurn,sieleq
    real(kind=8) :: alfafa, unsurn
!====================================================================
! - INITIALISATIONS
!====================================================================
    data  kron/1.d0,1.d0,1.d0,0.d0,0.d0,0.d0/
    cplan = typmod(1) .eq. 'C_PLAN'
    inco = typmod(2) .eq. 'INCO'
    elas = (compor(1)(1:5) .eq. 'ELAS ')
    vmis = (compor(1)(1:9) .eq. 'ELAS_VMIS')
    line = (compor(1)(1:14).eq. 'ELAS_VMIS_LINE')
    puis = (compor(1)(1:14).eq. 'ELAS_VMIS_PUIS')
    epsi = r8prem()
    energi(1) = 0.d0
    energi(2) = 0.d0
!
    if (.not.(elas .or. vmis)) then
        call utmess('F', 'ALGORITH4_50', sk=compor(1))
    endif
    ndimsi = 2*ndim
!====================================================================
! - LECTURE DES CARACTERISTIQUES ELASTIQUES
!====================================================================
    nomres(1)='E'
    nomres(2)='NU'
    nomres(3)='ALPHA'
!
! TEST SUR LA COHERENCE DES INFORMATIONS CONCERNANT LA TEMPERATURE
    call verift(fami, kpg, ksp, poum, imate,&
                epsth_=epsthe)
!
    call verift(fami, kpg, ksp, poum, imate,&
                epsth_=epsthe)
!
!
    call rcvarc(' ', 'TEMP', poum, fami, kpg,&
                ksp, temp, iret)
    call rcvarc(' ', 'HYDR', poum, fami, kpg,&
                ksp, hydr, ihyd)
    if (ihyd .ne. 0) hydr=0.d0
    call rcvarc(' ', 'SECH', poum, fami, kpg,&
                ksp, sech, isec)
    if (isec .ne. 0) sech=0.d0
    call rcvarc(' ', 'SECH', 'REF', fami, kpg,&
                ksp, secref, iret)
    if (iret .ne. 0) secref=0.d0
    if (elas .or. line .or. puis) then
        call rcvalb(fami, kpg, ksp, poum, imate,&
                    ' ', 'ELAS', 0, ' ', [0.d0],&
                    2, nomres, valres, icodre, 2)
        call rcvalb(fami, kpg, ksp, poum, imate,&
                    ' ', 'ELAS', 0, ' ', [0.d0],&
                    1, nomres(3), valres(3), icodre(3), 0)
        if (icodre(3) .ne. 0) valres(3)=0.d0
    else
        call rctrac(imate, 1, 'SIGM', temp, jprol,&
                    jvale, nbvale, valres(1))
        call rcvalb(fami, kpg, ksp, poum, imate,&
                    ' ', 'ELAS', 0, ' ', [0.d0],&
                    1, nomres(2), valres(2), icodre(2), 2)
!
        call rcvalb(fami, kpg, ksp, poum, imate,&
                    ' ', 'ELAS', 0, ' ', [0.d0],&
                    1, nomres(3), valres(3), icodre(3), 0)
        if (icodre(3) .ne. 0) valres(3)=0.d0
    endif
!
    e = valres(1)
    nu = valres(2)
!
    deuxmu = e/(1.d0+nu)
    if (abs(nu- 0.5d0) .ge. epsi) then
        troisk = e/(1.d0-2.d0*nu)
    else
        troisk = deuxmu
    endif
!
! --- RETRAIT ENDOGENE ET RETRAIT DE DESSICCATION
!
    nomres(4)='B_ENDOGE'
    nomres(5)='K_DESSIC'
    call rcvalb(fami, kpg, ksp, poum, imate,&
                ' ', 'ELAS', 0, ' ', [0.d0],&
                1, nomres(4), valres(4), icodre(4), 0)
    if (icodre(4) .ne. 0) valres(4) = 0.d0
    bendo = valres(4)
!
    call rcvalb(fami, kpg, ksp, poum, imate,&
                ' ', 'ELAS', 0, ' ', [0.d0],&
                1, nomres(5), valres(5), icodre(5), 0)
    if (icodre(5) .ne. 0) valres(5) = 0.d0
    kdess = valres(5)
!
!====================================================================
! - LECTURE DES CARACTERISTIQUES DE NON LINEARITE DU MATERIAU
!====================================================================
    if (line) then
        nomres(1)='D_SIGM_EPSI'
        nomres(2)='SY'
        call rcvalb(fami, kpg, ksp, poum, imate,&
                    ' ', 'ECRO_LINE', 0, ' ', [0.d0],&
                    2, nomres, valres, icodre, 2)
        dsde = valres(1)
        sigy = valres(2)
!
    else if (puis) then
        nomres(1)='SY'
        nomres(2)='A_PUIS'
        nomres(3)='N_PUIS'
        call rcvala(imate, ' ', 'ECRO_PUIS', 1, 'TEMP',&
                    [temp], 3, nomres, valres, icodre,&
                    2)
        sigy = valres(1)
        alfafa = valres(2)
        coco = e/alfafa/sigy
        unsurn = 1.d0/valres(3)
!
    else if (vmis) then
        call rcfonc('S', 1, jprol, jvale, nbvale,&
                    sigy = sigy)
    endif
!====================================================================
! CALCULS DIVERS
!====================================================================
! - CALCUL DE EPSMO ET EPSDV
    ther = epsthe - kdess*(secref-sech)- bendo*hydr
!
! TRAITEMENT PARTICULIER EN CONTRAINTE PLANE
    if (cplan) then
        eps(3)=-nu/(1.d0-nu)*(eps(1)+eps(2)) +(1.d0+nu)/(1.d0-nu)*&
        ther
    endif
    epsmo = 0.d0
!
! SI ON EST SUR UNE LOI ELASTIQUE, SI ON EST EN D_PLAN OU EN 3D,
! ON REGARDE LA VARIABLE DE COMMANDE PRESSION POUR LE CHAINAGE HM
!
    epspto = 0.d0
    if (elas .and. (.not.cplan)) then
        call rcvarc(' ', 'PTOT', poum, fami, kpg,&
                    ksp, ptot, iret)
!
        if (iret .eq. 0) then
            phenom = 'THM_DIFFU'
            nomres(1) = 'BIOT_COEF'
!
            call rcvalb(fami, kpg, ksp, poum, imate,&
                        ' ', phenom, 0, ' ', [0.d0],&
                        1, nomres, valres, icodre, 1)
!
            biot = valres(1)
!
            epspto = biot/troisk*ptot
!
        endif
!
    endif
!
    do k = 1, 3
        epsth(k) = eps(k) - ther - epspto
        epsth(k+3) = eps(k+3)
        epsmo = epsmo + epsth(k)
    end do
    epsmo = epsmo/3.d0
!
    do k = 1, ndimsi
        epsdv(k) = epsth(k) - epsmo * kron(k)
    end do
! - CALCUL DE LA CONTRAINTE ELASTIQUE EQUIVALENTE
    epseq = 0.d0
    do k = 1, ndimsi
        epseq = epseq + epsdv(k)*epsdv(k)
    end do
    epseq = sqrt(1.5d0*epseq)
    sieleq = deuxmu * epseq
    nonlin = .false.
    if (vmis) nonlin = (sieleq.ge.sigy)
!====================================================================
! CAS NON LINEAIRE
!====================================================================
! - CALCUL DE P, RP, RPRIM ET AIRERP
    if (nonlin) then
        iret=0
!===========================================
!      CAS DES CONTRAINTES PLANES
!===========================================
        if (cplan) then
!        REMPLISSAGE DU COMMON
            pm = 0.d0
            do k = 1, 4
                sigel(k) = deuxmu*epsdv(k)
            end do
            imate2 = imate
            if (line) then
                rprim = e*dsde/(e-dsde)
                lin = 1.d0
            else if (puis) then
                call utmess('F', 'ALGORITH_1')
            else
                jprol2 = jprol
                jvale2 = jvale
                nbval2 = nbvale
                call rcfonc('V', 1, jprol, jvale, nbvale,&
                            p = 0.d0, rp = rp, rprim = rprim, airerp = airerp)
                lin = 0.d0
            endif
!         CALCUL DE P (EQUATION PROPRE AUX CONTRAINTES PLANES)
            approx = 2.d0*epseq/3.d0 - sigy/1.5d0/deuxmu
            prec = abs(crit(3)) * sigy
            niter = abs(nint(crit(1)))
            call zerofr(0, 'DEKKER', nmcri1, 0.d0, approx,&
                        prec, niter, p, iret, ibid)
            if (iret .ne. 0) then
                call utmess('F', 'ALGORITH8_65')
            endif
            if (line) then
                rp = sigy +rprim*p
                airerp = 0.5d0*(sigy+rp)*p
            else if (puis) then
                call utmess('F', 'ALGORITH_1')
            else
                call rcfonc('V', 1, jprol, jvale, nbvale,&
                            p = p, rp = rp, rprim = rprim, airerp = airerp)
            endif
!
            epseq = 1.5d0*p + rp/deuxmu
            g = rp/epseq
            x = 3*(deuxmu-g)/(troisk+2*g)*epsdv(3)
            epsmo = epsmo +x/3.d0
            eps(3) = eps(3) + x
            epsdv(1)= epsdv(1)-x/3.d0
            epsdv(2)= epsdv(2)-x/3.d0
            epsdv(3)= epsdv(3)+x*2.d0/3.d0
!      CAS 2D OU 3D
        else
!===========================================
! NON CONTRAINTE PLANE
!===========================================
            pm=0.d0
            if (line) then
                rprim = e*dsde/(e-dsde)
                p = (sieleq - sigy) / (rprim+1.5d0*deuxmu)
                rp = sigy +rprim*p
                airerp = 0.5d0*(sigy+rp)*p
            else if (puis) then
!           AMELIORATION DE LA PREDICTION EN ESTIMANT RPRIM(PM+DP0)
                dp0 = ( sieleq - sigy)/1.5d0/deuxmu
                rprim0 = unsurn*sigy*coco * (coco*dp0)**(unsurn-1.d0)
                dp0 = dp0 / (1+rprim0/1.5d0/deuxmu)
                xap = dp0
                precr = crit(3) * sigy
                niter = nint(crit(1))
                call zerofr(0, 'DEKKER', nmcri2, 0.d0, xap,&
                            precr, niter, p, iret, ibid)
                if (iret .ne. 0) then
                    call utmess('F', 'ALGORITH8_65')
                endif
                call ecpuis(e, sigy, alfafa, unsurn, pm,&
                            p, rp, rprim)
            else
                call rcfonc('E', 1, jprol, jvale, nbvale,&
                            e = e, nu = nu, p = 0.d0, rp = rp, rprim = rprim,&
                            airerp = airerp, sieleq = sieleq, dp = p)
            endif
            g = rp/epseq
        endif
!====================================================================
! CAS LINEAIRE
!====================================================================
    else
        g = deuxmu
    endif
!====================================================================
! - CALCUL DES CONTRAINTES ET DES PSEUDO VARIABLES INTERNES
!====================================================================
    if (inco) then
        do k = 1, ndimsi
            sig(k) = g*epsdv(k)
        end do
    else
        do k = 1, ndimsi
            sig(k) = troisk*epsmo*kron(k) + g*epsdv(k)
        end do
    endif
!====================================================================
! TRAITEMENTS PARTICULIERS
!====================================================================
    if (option(1:9) .eq. 'RAPH_MECA' .or. option(1:9) .eq. 'FULL_MECA' .or. option(1:7)&
        .eq. 'RUPTURE') then
        if (nonlin) then
            vi = p
        else if (vmis) then
            vi = 0.d0
        endif
    endif
! - CALCUL DE LA MATRICE DE RIGIDITE TANGENTE
    if (option(1:10) .eq. 'RIGI_MECA_' .or. option .eq. 'RIGI_MECA' .or. option(1:9) .eq.&
        'FULL_MECA') then
!
        do k = 1, ndimsi
            do l = 1, ndimsi
                dsidep(k,l) = 0.d0
            end do
        end do
!      TERME LINEAIRE
        do k = 1, 3
            do l = 1, 3
                dsidep(k,l) = (troisk-g)/3.d0
            end do
        end do
        do k = 1, ndimsi
            dsidep(k,k) = dsidep(k,k) + g
        end do
!      TERME NON LINEAIRE
        if (nonlin .and. (option(11:14).ne.'ELAS')) then
            coef = deuxmu*rprim/(1.5d0*deuxmu+rprim) - g
            coef = coef * 3.d0 / (2.d0*epseq*epseq)
            do k = 1, ndimsi
                do l = 1, ndimsi
                    dsidep(k,l) = dsidep(k,l) + coef*epsdv(k)*epsdv(l)
                end do
            end do
        endif
!      CORRECTION POUR LES CONTRAINTES PLANES
        if (cplan) then
            do 130 k = 1, ndimsi
                if (k .eq. 3) goto 130
                do 140 l = 1, ndimsi
                    if (l .eq. 3) goto 140
                    dsidep(k,l)=dsidep(k,l) - 1.d0/dsidep(3,3)*dsidep(&
                    k,3)*dsidep(3,l)
140             continue
130         continue
        endif
    endif
!====================================================================
! CALCUL DE L'ENERGIE LIBRE
!====================================================================
! CALCUL DE L'ENERGIE LIBRE ENERGI(1) ET DE SA DERIVEE / T ENERGI(2)
    if (option(1:7) .eq. 'RUPTURE') then
        divu = 3.d0*epsmo
        call nmelru(fami, kpg, ksp, poum,&
                    imate, compor, epseq, p, divu,&
                    nonlin, energi)
    endif
end subroutine
