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
! person_in_charge: mickael.abbas at edf.fr
!
subroutine op0033()
!
use NonLin_Datastructure_type
!
implicit none
!
#include "asterf_types.h"
#include "jeveux.h"
#include "asterfort/assert.h"
#include "asterfort/detrsd.h"
#include "asterfort/dierre.h"
#include "asterfort/diinst.h"
#include "asterfort/fointe.h"
#include "asterfort/getvid.h"
#include "asterfort/infmaj.h"
#include "asterfort/jedema.h"
#include "asterfort/jemarq.h"
#include "asterfort/jeveut.h"
#include "asterfort/lcdetf.h"
#include "asterfort/matinv.h"
#include "asterfort/mgauss.h"
#include "asterfort/nmadat.h"
#include "asterfort/nmcomp.h"
#include "asterfort/nmcpel.h"
#include "asterfort/nmcrcv.h"
#include "asterfort/nmfinp.h"
#include "asterfort/pmactn.h"
#include "asterfort/pmat.h"
#include "asterfort/pmconv.h"
#include "asterfort/pmdorc.h"
#include "asterfort/pmdrdy.h"
#include "asterfort/pmimpr.h"
#include "asterfort/pminit.h"
#include "asterfort/pmmaco.h"
#include "asterfort/pmsta1.h"
#include "asterfort/pmstab.h"
#include "asterfort/pmvtgt.h"
#include "asterfort/tnsvec.h"
#include "asterfort/utbtab.h"
#include "asterfort/utmess.h"
#include "asterfort/vrcinp.h"
#include "asterfort/wkvect.h"
#include "asterfort/nonlinDSConvergenceCreate.h"
#include "asterfort/nonlinDSAlgoParaCreate.h"
#include "asterfort/Behaviour_type.h"
#include "blas/daxpy.h"
#include "blas/dcopy.h"
#include "blas/dscal.h"
!
! --------------------------------------------------------------------------------------------------
!
! CALC_POINT_MAT
!
! --------------------------------------------------------------------------------------------------
!
    integer :: ndim, iret, nbmat, nbvari, nbpar, i, ier
    integer :: imate, kpg, ksp, iter, pred, ncmp, imptgt
    integer :: matrel, irota, defimp, liccvg(5)
    integer :: indimp(9), nume_inst, actite, action, itgt, iforta
!     NOMBRE MAXI DE COLONNES DANS UNE TABLE 9999 (CF D4.02.05)
    integer, parameter ::  ntamax = 9999
    integer :: igrad, nbvita
    character(len=4) :: fami, cargau
    character(len=8) :: typmod(2), mater(30), table, fonimp(9), typpar(ntamax)
    character(len=16) :: option, compor(COMPOR_SIZE), nompar(ntamax), opt2, mult_comp, type_comp
    character(len=19) :: codi, sddisc, k19b, sdcrit
    character(len=24) :: sderro
    real(kind=8) :: instam, instap, ang(7), r8b, carcri(CARCRI_SIZE), fem(9)
    real(kind=8) :: deps(9), sigm(6), sigp(6), epsm(9), eps(9), vr(ntamax)
    real(kind=8) :: valimp(9), r(12), rini(12), dy(12), ddy(12), y(12), rac2
    real(kind=8) :: dsidep(6, 9), drdy(12, 12), kel(6, 6), cimpo(6, 12), ym(12)
    real(kind=8) :: work(10), sdeps(6), ssigp(6), smatr(36), r1(12)
    real(kind=8) :: matper(36), varia(2*36), epsilo, pgl(3, 3), vimp33(3, 3)
    real(kind=8) :: vimp2(3, 3), coef, jm, jp, jd, rbid(1), coefextra
    aster_logical :: finpas, itemax, conver
    character(len=19) :: nomvi
    character(len=19) :: vim, vip, vim2, svip
    integer :: lvim, lvip, lvim2, lsvip, lnomvi
    type(NL_DS_Conv) :: ds_conv
    type(NL_DS_AlgoPara) :: ds_algopara
!
    data sddisc  /'&&OP0033.SDDISC'/
    data sdcrit  /'&&OP0033.SDCRIT'/
    data sderro  /'&&OP0033.ERRE.'/
!
    data vim     /'&&OP0033.VIM'/
    data vip     /'&&OP0033.VIP'/
    data svip    /'&&OP0033.SVIP'/
    data vim2    /'&&OP0033.VIM2'/
    data nomvi   /'&&OP0033.NOMVI'/
!
! --------------------------------------------------------------------------------------------------
!
    call infmaj()
    call jemarq()
!
! - Initializations
!
    work(:)     = 0.d0
    dsidep(:,:) = 0.d0
    ndim        = 3
    rac2        = sqrt(2.d0)
    fami        = 'PMAT'
    kpg         = 1
    ksp         = 1
    k19b        = ' '
    iter        = 0
    action      = 1
    finpas      = ASTER_FALSE
    itemax      = ASTER_FALSE
    liccvg(1:5) = 0
!
! - Create convergence management datastructure
!
    call nonlinDSConvergenceCreate(ds_conv)
!
! - Create algorithm parameters datastructure
!
    call nonlinDSAlgoParaCreate(ds_algopara)
!
! - Get material parameters
!
    call getvid(' ', 'MATER', nbval=6, vect=mater, nbret=nbmat)
!
! - Get behaviours parameters
!
    call pmdorc(compor, carcri, nbvari, type_comp, mult_comp)
    ASSERT(type_comp .eq. 'COMP_INCR' .or. type_comp .eq. 'COMP_ELAS')
!
! - Create working vectors
!
    call wkvect(vim, 'V V R', nbvari, lvim)
    call wkvect(vip, 'V V R', nbvari, lvip)
    call wkvect(svip, 'V V R', nbvari, lsvip)
    call wkvect(vim2, 'V V R', nbvari, lvim2)
    call wkvect(nomvi, 'V V K8', nbvari, lnomvi)
!
! - Coding material parameters
!
    call pmmaco(mater, nbmat, codi)
    call jeveut(codi//'.CODI', 'L', imate)
!
! - External state variables
!
    call vrcinp(1, 0.d0, 0.d0)
!
!     INITIALISATIONS SD
!
    call pminit(imate, nbvari, ndim, typmod, table,&
                nbpar, iforta, nompar, typpar, ang,&
                pgl, irota, epsm, sigm, zr(lvim),&
                zr(lvip), vr, defimp, coef, indimp,&
                fonimp, cimpo, kel, sddisc, ds_conv, ds_algopara, &
                pred, matrel, imptgt, option, zk8(lnomvi),&
                nbvita, sderro)
!
! - Message if PETIT_REAC
!
    if (defimp .gt. 0) then
        if (compor(DEFO) .eq. 'PETIT_REAC') then
            call utmess('I', 'COMPOR2_93')
        endif
    endif
!
! --- CREATION DE LA SD POUR ARCHIVAGE DES INFORMATIONS DE CONVERGENCE
!
    call nmcrcv(sdcrit)
    nume_inst=1
!
!==================================
!     BOUCLE SUR lES INSTANTS
!==================================
!
200 continue
!
    liccvg(1:5)=0
!
! - Get times
!
    instam = diinst(sddisc, nume_inst-1)
    instap = diinst(sddisc, nume_inst )
!
! - Compute external state variables
!
    call vrcinp(2, instam, instap)
!
! - Prepare stress/strain to impose
!
    if (defimp .lt. 2) then
        igrad = 0
        do i = 1, 6
            call fointe('F', fonimp(i), 1, ['INST'], [instap], valimp(i), ier)
!               NORMALISATION DES TERMES EN CONTRAINTES
            if (indimp(i) .eq. 0) then
                valimp(i) = valimp(i)/coef
            endif
        end do
        ASSERT(compor(DEFO).eq.'PETIT')
    else if (defimp .eq. 2) then
        igrad=1
!           VALEURS IMPOSEES DE GRADIENTS F
        do i = 1, 9
            call fointe('F', fonimp(i), 1, ['INST'], [instap], valimp(i), ier)
        end do
    endif
!
    if (irota .eq. 1) then
        call tnsvec(6, ndim, vimp33, valimp, 1.0d0)
        call utbtab('ZERO', 3, 3, vimp33, pgl,&
                    work, vimp2)
        call tnsvec(3, ndim, vimp2, valimp, 1.0d0)
    endif
!        CISAILLEMENTS*SQRT(2) POUR NMCOMP
    if (defimp .lt. 2) then
        call dscal(3, rac2, valimp(4), 1)
    endif
!
!        6 CMP DE EPSI OU 9 CMP DE GRAD DONNEES : PAS BESOIN DE NEWTON
    if ((defimp.ge.1) .and. (abs(carcri(2)).lt.0.1d0)) then
        opt2='RAPH_MECA'
        if (imptgt .eq. 1) opt2='FULL_MECA'
        if (defimp .eq. 1) then
            ncmp=6
            do i = 1, ncmp
                deps(i)=valimp(i)-epsm(i)
            end do
        else if (defimp.eq.2) then
            ncmp=9
            call matinv('S', 3, epsm, fem, jm)
            call pmat(3, valimp, fem, deps)
            call lcdetf(3, deps, jd)
            jp = jm*jd
        endif
        if (type_comp .eq. 'COMP_INCR') then
            call dcopy(nbvari, zr(lvim), 1, zr(lvim2), 1)
            call nmcomp(fami, kpg, ksp, ndim, typmod,&
                        imate, compor, carcri, instam, instap,&
                        ncmp, epsm, deps, 6, sigm,&
                        zr(lvim2), opt2, ang, 10, work,&
                        sigp, zr(lvip), 6*ncmp, dsidep, 1,&
                        rbid, iret, mult_comp)
            if (compor(DEFO) .eq. 'SIMO_MIEHE') then
                call dscal(2*ndim, 1.d0/jp, sigp, 1)
            endif
        else if (type_comp .eq. 'COMP_ELAS') then
            call dcopy(ncmp, epsm, 1, eps, 1)
            call daxpy(ncmp, 1.d0, deps, 1, eps, 1)
            call nmcpel(fami, kpg, 1, '+', ndim,&
                        typmod, ang, imate, compor, carcri,&
                        option, eps, sigp, zr(lvip), dsidep,&
                        iret)
        endif
        call pmimpr(0, instap, indimp, valimp,&
                    0, epsm, sigm, zr(lvim), nbvari,&
                    r, r8b, r8b)
        if (iret .ne. 0) then
            liccvg(2) = 1
            goto 500
        endif
        goto 550
    endif
!
!        INITIALISATION DE L'ALGO DE NEWTON
!
    call dcopy(6, sigm, 1, ym, 1)
    call dscal(6, 1.d0/coef, ym, 1)
    call dcopy(6, epsm, 1, ym(7), 1)
!
    if (pred .eq. 1) then
        dy(:)   = 0.d0
        deps(:) = 0.d0
        opt2='RIGI_MECA_TANG'
        call dcopy(nbvari, zr(lvim), 1, zr(lsvip), 1)
        if (type_comp .eq. 'COMP_INCR') then
            call nmcomp(fami, kpg, ksp, ndim, typmod,&
                        imate, compor, carcri, instam, instap,&
                        6, epsm, deps, 6, sigm,&
                        zr(lsvip), opt2, ang, 10, work,&
                        ssigp, zr(lsvip), 36, dsidep, 1,&
                        rbid, iret, mult_comp)
        else if (type_comp .eq. 'COMP_ELAS') then
            call nmcpel(fami, kpg, 1, '+', ndim,&
                        typmod, ang, imate, compor, carcri,&
                        option, epsm, sigp, zr(lvip), dsidep,&
                        iret)
        endif
        if (iret .ne. 0) then
            pred=0
        else
            call pmdrdy(dsidep, coef, cimpo, valimp, ym,&
                        sigm, r, drdy)
        endif
    else if ((pred .eq. 0).or.((pred.eq.-1).and.(nume_inst.eq.1))) then
        dy(:)   = 0.d0
        deps(:) = 0.d0
        call pmdrdy(kel, coef, cimpo, valimp, ym,&
                    sigm, r, drdy)
    endif
!        SAUVEGARDE DE R(DY0) POUR TEST DE CONVERGENCE
    call dcopy(12, r, 1, rini, 1)
    call pmimpr(0, instap, indimp, valimp,&
                0, epsm, sigm, zr(lvim), nbvari,&
                r, r8b, r8b)
!
    iter = 0
!
!:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
!           ITERATIONS DE NEWTON
!:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
!
300 continue
!
    iter = iter + 1
!
    if ((iter.eq.1) .and. (pred.eq.-1) .and. (nume_inst.gt.1)) then
!   prediction='extrapole'
        coefextra = (instap-instam)/(instam-diinst(sddisc, nume_inst-2))
!       dy = dy * (ti - ti-1)/(ti-1 - ti-2)
        call dscal(12, coefextra, dy, 1)
    else
!
        call dcopy(12, r, 1, ddy, 1)
!
!      RESOLUTION DE DRDY*DDY = - R(Y)  CARGAU = 'NCSP'
        cargau = 'NCWP'
        call mgauss(cargau, drdy, ddy, 12, 12,&
                    1, r8b, iret)
        if (iret .ne. 0) then
            liccvg(5) = 1
            conver = ASTER_FALSE
            goto 500
        endif
!
!      REACTUALISATION DE DY = DY + DDY
        call daxpy(12, 1.d0, ddy, 1, dy, 1)
!
    endif
!
    call dcopy(6, dy(7), 1, deps, 1)
!
!           POUR LE CALCUL DE LA MATRICE TANGENTE PAR PERTURBATION
400 continue
!
!           CALCUL DU RESIDU
    liccvg(2) = 0
    if (type_comp .eq. 'COMP_INCR') then
        call dcopy(nbvari, zr(lvim), 1, zr(lvim2), 1)
        call nmcomp(fami, kpg, ksp, ndim, typmod,&
                    imate, compor, carcri, instam, instap,&
                    6, epsm, deps, 6, sigm,&
                    zr(lvim2), option, ang, 10, work,&
                    sigp, zr(lvip), 36, dsidep, 1,&
                    rbid, iret, mult_comp)
    else if (type_comp .eq. 'COMP_ELAS') then
        call dcopy(6, epsm, 1, eps, 1)
        call daxpy(6, 1.d0, deps, 1, eps, 1)
        call nmcpel(fami, kpg, 1, '+', ndim,&
                    typmod, ang, imate, compor, carcri,&
                    option, eps, sigp, zr(lvip), dsidep,&
                    iret)
    endif
!
    call pmimpr(1, instap, indimp, valimp,&
                iter, deps, sigp, zr(lvip), nbvari,&
                r, r8b, r8b)
    if (iret .ne. 0) then
        conver = ASTER_FALSE
        liccvg(2) = 1
        goto 500
    endif
!
!           CALCUL EVENTUEL DE LA MATRICE TGTE PAR PERTURBATION
    call pmvtgt(option, carcri, deps, sigp, zr(lvip),&
                nbvari, epsilo, varia, matper, dsidep,&
                smatr, sdeps, ssigp, zr(lsvip), itgt)
    if (itgt .ne. 0) then
        goto 400
    endif
!
    call dcopy(12, ym, 1, y, 1)
    call daxpy(12, 1.d0, dy, 1, y, 1)
    if (matrel .eq. 1) then
        call pmdrdy(kel, coef, cimpo, valimp, y,&
                    sigp, r, drdy)
    else
        call pmdrdy(dsidep, coef, cimpo, valimp, y,&
                    sigp, r, drdy)
    endif
!
!           VERIFICATION DE LA CONVERGENCE EN DY  ET RE-INTEGRATION ?
    call pmconv(r, rini, r1, instap, sigp,&
                coef, iter, indimp, ds_conv, conver,&
                itemax)
!
!           ENREGISTRE LES RESIDUS A CETTE ITERATION
    call dierre(sddisc, sdcrit, iter)
!
!           VERIFICATION DES EVENT-DRIVEN
500 continue
    call pmsta1(sigm, sigp, deps, zr(lvim), zr(lvip),&
                nbvari, nbvita, iforta, nbpar, nompar,&
                vr, igrad, typpar, zk8(lnomvi), sddisc,&
                liccvg, itemax, conver, actite)
!
!           ON CONTINUE NEWTON
    if (actite .eq. 2) goto 300
!
! ======================================================================
!     FIN DES ITERATIONS DE NEWTON
! ======================================================================
!
!        GESTION DE LA DECOUPE DU PAS DE TEMPS
!        EN L'ABSENCE DE CONVERGENCE ON CHERCHE A SUBDIVISER LE PAS
!        DE TEMPS SI L'UTILISATEUR A FAIT LA DEMANDE
    call pmactn(sddisc, ds_conv, iter, nume_inst, itemax,&
                sderro, liccvg , actite, action)
!
! ---    ACTION
!          0 ARRET DU CALCUL
!          1 NOUVEAU PAS DE TEMPS
!          2 ON FAIT DES ITERATIONS DE NEWTON EN PLUS
!          3 ON FINIT LE PAS DE TEMPS
    if (action .eq. 1) then
        goto 600
    else if (action.eq.2) then
        goto 300
    else if (action.eq.3) then
        goto 550
    else if (action.eq.0) then
        goto 550
    endif
!:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
!
550 continue
!
!        ---------------------------------------------------------------
!        CONVERGENCE => MISE A JOUR DE SIGM,ZR(LVIM), TABLE
!        ---------------------------------------------------------------
!
!        ADAPTATION DU NOUVEAU PAS DE TEMPS
!        PAS DE GESTION DE DELTA_GRANDEUR ACTUELLEMENT
    call nmfinp(sddisc, nume_inst, finpas)
    if (.not.finpas) call nmadat(sddisc, nume_inst, iter, k19b)
    nume_inst=nume_inst+1
!        STOCKAGE EFFECTIF DU RESULTAT DANS LA TABLE
    call pmstab(sigm, sigp, epsm, deps, nbvari,&
                zr(lvim), zr(lvip), iforta, instam, instap,&
                iter, nbpar, nompar, table, vr,&
                igrad, valimp, imptgt, dsidep, zk8(lnomvi),&
                nbvita)
    call pmimpr(2, instap, indimp, valimp,&
                iter, deps, sigp, zr(lvip), nbvari,&
                r, r8b, r8b)
!
600 continue
!
! --- DERNIER INSTANT DE CALCUL ? -> ON SORT DE STAT_NON_LINE
!
    if (finpas .or. (action.eq.0)) then
        goto 900
    endif
    goto 200
!==================================
!     FIN BOUCLE SUR LES INSTANTS
!==================================
!
900 continue
!
!     GESTION DES VARIABLES DE COMMANDE
    call vrcinp(0, instam, instap)
!
!
!     DESTRUCTION DE lA FONCTION F0 NULLE
    call detrsd('FONCTION', '&&CPM_F0')
!
    call jedema()
end subroutine
