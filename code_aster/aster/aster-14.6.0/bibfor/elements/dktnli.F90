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

subroutine dktnli(nomte, opt, xyzl, pgl, ul, dul,&
                  btsig, ktan, codret)
    implicit none
#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/r8vide.h"
#include "asterfort/assert.h"
#include "asterfort/dkqbf.h"
#include "asterfort/dktbf.h"
#include "asterfort/dxqbm.h"
#include "asterfort/dxqloc.h"
#include "asterfort/dxdmul.h"
#include "asterfort/dxtbm.h"
#include "asterfort/dxtloc.h"
#include "asterfort/dsxhft.h"
#include "asterfort/dkttxy.h"
#include "asterfort/dkqtxy.h"
#include "asterfort/dkqlxy.h"
#include "asterfort/dktlxy.h"
#include "asterfort/dsxhlt.h"
#include "asterfort/dxmate.h"
#include "asterfort/elrefe_info.h"
#include "asterfort/gquad4.h"
#include "asterfort/gtria3.h"
#include "asterfort/jevech.h"
#include "asterfort/jquad4.h"
#include "asterfort/nmcomp.h"
#include "asterfort/pmrvec.h"
#include "asterfort/r8inir.h"
#include "asterfort/tecach.h"
#include "asterfort/utbtab.h"
#include "asterfort/utctab.h"
#include "asterfort/utmess.h"
#include "blas/dcopy.h"
!
    integer :: codret
    real(kind=8) :: xyzl(3, *), ul(6, *), dul(6, *)
    real(kind=8) :: ktan(*), btsig(6, *)
    character(len=16) :: nomte, opt
    real(kind=8) :: pgl(3, 3)
!
!
!     ------------------------------------------------------------------
!     CALCUL DES OPTIONS NON LINEAIRES POUR L'ELEMENT DE PLAQUE DKT
!     TOUTES LES ENTREES ET LES SORTIES SONT DANS LE REPERE LOCAL.
!     (MEME SI LES TABLEAUX SONT DIMMENSIONNES EN 3D)
!     ------------------------------------------------------------------
!     IN  OPT  : OPTION NON LINEAIRE A CALCULER
!                  'RAPH_MECA'
!                  'FULL_MECA'      OU 'FULL_MECA_ELAS'
!                  'RIGI_MECA_TANG' OU 'RIGI_MECA_ELAS'
!     IN  XYZL : COORDONNEES DES NOEUDS
!     IN  UL   : DEPLACEMENT A L'INSTANT T "-"
!     IN  DUL  : INCREMENT DE DEPLACEMENT
!     IN  PGL  : MATRICE DE PASSAGE GLOBAL - LOCAL ELEMENT
!     OUT KTAN : MATRICE DE RIGIDITE TANGENTE
!                    SI 'FULL_MECA' OU 'RIGI_MECA_TANG'
!     OUT BTSIG: DIV (SIGMA)
!                    SI 'FULL_MECA' OU 'RAPH_MECA'
!     ------------------------------------------------------------------
!     CHARACTER*32 JEXNUM,JEXNOM,JEXR8,JEXATR
!
    character(len=8) :: typmod(2)
!CC      PARAMETER (NNO=3)  POUR LES DKT
!CC      PARAMETER (NNO=4)  POUR LES DKQ
    integer :: nno
    parameter (nno=4)
!            NNO:    NOMBRE DE NOEUDS DE L'ELEMENT
    real(kind=8) :: distn, angmas(3), wk(1)
!
! --------- VARIABLES LOCALES :
!  -- GENERALITES :
!  ----------------
!  CMPS DE DEPLACEMENT :
!   - MEMBRANE : DX(N1), DY(N1), DX(N2), ..., DY(NNO)
!   - FLEXION  : DZ(N1), BETAX(N1), BETAY(N1), DZ(N2), ..., BETAY(NNO)
!  CMPS DE DEFORMATION ET CONTRAINTE PLANE (DANS UNE COUCHE) :
!   -            EPSIXX,EPSIYY,2*EPSIXY
!   -            SIGMXX,SIGMYY,SIGMXY
!  CMPS DE DEFORMATION ET CONTRAINTE PLANE POUR APPEL NMCOMP :
!   -            EPSIXX,EPSIYY,EPSIZZ,SQRT(2)*EPSIXY
!   -            SIGMXX,SIGMYY,SIGMZZ,SQRT(2)*SIGMXY
!  CMPS DE DEFORMATION COQUE :
!   - MEMBRANE : EPSIXX,EPSIYY,2*EPSIXY
!   - FLEXION  : KHIXX,KHIYY,2*KHIXY
!  CMPS D' EFFORTS COQUE :
!   - MEMBRANE : NXX,NYY,NXY
!   - FLEXION  : MXX,MYY,MXY
! --------------------------------------------------------------------
    integer :: nbcou, npgh, jnbspi
!            NBCOU:  NOMBRE DE COUCHES (INTEGRATION DE LA PLASTICITE)
!            NPG:    NOMBRE DE POINTS DE GAUSS PAR ELEMENT
!            NC :    NOMBRE DE COTES DE L'ELEMENT
!            NPGH:   NOMBRE DE POINT D'INTEGRATION PAR COUCHE
    real(kind=8) :: poids, hic, h, zic, zmin, instm, instp, coef
!            POIDS:  POIDS DE GAUSS (Y COMPRIS LE JACOBIEN)
!            AIRE:   SURFACE DE L'ELEMENT
!            HIC:    EPAISSEUR D'UNE COUCHE
!            H :     EPAISSEUR TOTALE DE LA PLAQUE
!            ZIC:    COTE DU POINT D'INTEGRATION DANS L'EPAISSEUR
!            ZMIN:   COTE DU POINT D'INTEGRATION LE PLUS "BAS"
!            INSTM:  INSTANT "-"
!            INSTP:  INSTANT "+"
!            COEF:   POIDS D'INTEGRATION PAR COUCHE
    real(kind=8) :: um(2, nno), uf(3, nno), dum(2, nno), duf(3, nno)
!            UM:     DEPLACEMENT (MEMBRANE) "-"
!            UF:     DEPLACEMENT (FLEXION)  "-"
!           DUM:     INCREMENT DEPLACEMENT (MEMBRANE)
!           DUF:     INCREMENT DEPLACEMENT (FLEXION)
    real(kind=8) :: eps2d(6), deps2d(6), dsidep(6, 6)
!            EPS2D:  DEFORMATION DANS UNE COUCHE (2D C_PLAN)
!           DEPS2D:  INCREMENT DEFORMATION DANS UNE COUCHE (2D C_PLAN)
!            SIG2D:  CONTRAINTE DANS UNE COUCHE (2D C_PLAN)
!           DSIDEP:  MATRICE D(SIG2D)/D(EPS2D)
    real(kind=8) :: eps(3), khi(3), deps(3), dkhi(3), n(3), m(3), sigm(4)
!    real(kind=8) :: q(2)
!            EPS:    DEFORMATION DE MEMBRANE "-"
!            DEPS:   INCREMENT DE DEFORMATION DE MEMBRANE
!            KHI:    DEFORMATION DE FLEXION  "-"
!            DKHI:   INCREMENT DE DEFORMATION DE FLEXION
!            N  :    EFFORT NORMAL "+"
!            M  :    MOMENT FLECHISSANT "+"
!            Q  :    EFFORT TRANCHANT
!            SIGM : CONTRAINTE "-"
    real(kind=8) :: df(9), dm(9), dmf(9), d2d(9)
!            D2D:    MATRICE DE RIGIDITE TANGENTE MATERIELLE (2D)
!            DF :    MATRICE DE RIGIDITE TANGENTE MATERIELLE (FLEXION)
!            DM :    MATRICE DE RIGIDITE TANGENTE MATERIELLE (MEMBRANE)
!            DMF:    MATRICE DE RIGIDITE TANGENTE MATERIELLE (COUPLAGE)
    real(kind=8) :: bf(3, 3*nno), bm(3, 2*nno), bmq(2, 3)
!            BF :    MATRICE "B" (FLEXION)
!            BM :    MATRICE "B" (MEMBRANE)
    real(kind=8) :: flex(3*nno*3*nno), memb(2*nno*2*nno)
    real(kind=8) :: mefl(2*nno*3*nno), work(3*nno*3*nno)
!           MEMB:    MATRICE DE RIGIDITE DE MEMBRANE
!           FLEX:    MATRICE DE RIGIDITE DE FLEXION
!           WORK:    TABLEAU DE TRAVAIL
!           MEFL:    MATRICE DE COUPLAGE MEMBRANE-FLEXION
!             LE MATERIAU EST SUPPOSE HOMOGENE
!             IL PEUT NEANMOINS Y AVOIR COUPLAGE PAR LA PLASTICITE
!     ------------------ PARAMETRAGE ELEMENT ---------------------------
    integer :: ndim, nnoel, nnos, npg, ipoids, icoopg, ivf, idfdx, idfd2, jgano
    integer :: jtab(7), cod, i, ksp
    integer :: icacoq, icarcr, icompo, icontm, icontp, icou, icpg, igauh, iinstm
    integer :: iinstp, imate, ino, ipg, iret, isp, ivarim, ivarip, ivarix, ivpg
    integer :: j, k, nbcon, nbsp, nbvar, ndimv
    real(kind=8) :: deux, rac2, qsi, eta, cara(25), jacob(5)
    real(kind=8) :: ctor, coehsd, zmax, quotient, a, b, c
    aster_logical :: vecteu, matric, dkt, dkq, leul
    real(kind=8) :: dvt(2),vt(2)
    real(kind=8) :: dfel(3, 3), dmel(3, 3), dmfel(3, 3), dcel(2, 2), dciel(2, 2)
    real(kind=8) :: dmcel(3, 2), dfcel(3, 2)
    real(kind=8) :: d1iel(2, 2)
    real(kind=8) :: depfel(3*nno)
    real(kind=8) :: hft2el(2, 6)
    real(kind=8) ::   t2iuel(4), t2uiel(4), t1veel(9)
    aster_logical :: coupmfel
    integer :: multicel,pcontr
    character(len=4), parameter :: fami = 'RIGI'
!     ------------------------------------------------------------------
!
    call elrefe_info(fami='RIGI', ndim=ndim, nno=nnoel, nnos=nnos, npg=npg,&
                     jpoids=ipoids, jcoopg=icoopg, jvf=ivf, jdfde=idfdx, jdfd2=idfd2,&
                     jgano=jgano)
!
    deux = 2.d0
    rac2 = sqrt(deux)
    codret = 0
!
!     2 BOOLEENS COMMODES :
!     ---------------------
    vecteu = ((opt(1:9).eq.'FULL_MECA').or.(opt.eq.'RAPH_MECA'))
    matric = ((opt(1:9).eq.'FULL_MECA').or.(opt(1:9).eq.'RIGI_MECA'))
!     RECUPERATION DES OBJETS &INEL ET DES CHAMPS PARAMETRES :
!     --------------------------------------------------------
    dkt = .false.
    dkq = .false.
!
    if (nomte .eq. 'MEDKTR3 ') then
        dkt = .true.
    else if (nomte.eq.'MEDKQU4 ') then
        dkq = .true.
    else
        call utmess('F', 'ELEMENTS_34', sk=nomte)
    endif
!
    call jevech('PMATERC', 'L', imate)
!
    call tecach('OOO', 'PCONTMR', 'L', iret, nval=7,&
                itab=jtab)
    nbsp=jtab(7)
    icontm=jtab(1)
    ASSERT(npg.eq.jtab(3))
!
    call jevech('PVARIMR', 'L', ivarim)
    call jevech('PINSTMR', 'L', iinstm)
    call jevech('PINSTPR', 'L', iinstp)
    instm = zr(iinstm)
    instp = zr(iinstp)
!
    call jevech('PCOMPOR', 'L', icompo)
    call jevech('PCARCRI', 'L', icarcr)
    call jevech('PCACOQU', 'L', icacoq)
!
    leul = zk16(icompo+2).eq.'GROT_GDEP'
    if (leul .and. zk16(icompo)(1:4) .ne. 'ELAS') then
        call utmess('F', 'ELEMENTS2_73')
    endif
!
    if (vecteu) then
        call jevech('PCONTPR', 'E', icontp)
        call jevech('PVARIPR', 'E', ivarip)
    else
!       -- POUR AVOIR UN TABLEAU BIDON A DONNER A NMCOMP :
        ivarip = ivarim
        icontp = icontm
    endif
!
!     -- GRANDEURS GEOMETRIQUES :
!     ---------------------------
    h = zr(icacoq)
    distn = zr(icacoq+4)
    if (dkt) then
        call gtria3(xyzl, cara)
        ctor = zr(icacoq+3)
    else if (dkq) then
        call gquad4(xyzl, cara)
        ctor = zr(icacoq+3)
    endif
!
!     -- MISES A ZERO :
!     ------------------
    if (matric) then
        call r8inir((3*nnoel)* (3*nnoel), 0.d0, flex, 1)
        call r8inir((2*nnoel)* (2*nnoel), 0.d0, memb, 1)
        call r8inir((2*nnoel)* (3*nnoel), 0.d0, mefl, 1)
    endif
    if (vecteu) then
        call r8inir(6*nnoel, 0.d0, btsig, 1)
    endif
!
!     -- PARTITION DU DEPLACEMENT EN MEMBRANE/FLEXION :
!     -------------------------------------------------
    do  ino = 1, nnoel
        um(1,ino) = ul(1,ino)
        um(2,ino) = ul(2,ino)
        uf(1,ino) = ul(3,ino)
        uf(2,ino) = ul(5,ino)
        uf(3,ino) = -ul(4,ino)
        dum(1,ino) = dul(1,ino)
        dum(2,ino) = dul(2,ino)
        duf(1,ino) = dul(3,ino)
        duf(2,ino) = dul(5,ino)
        duf(3,ino) = -dul(4,ino)
    end do
!
!     -- INTEGRATIONS SUR LA SURFACE DE L'ELEMENT:
!     --------------------------------------------
!     -- POUR POUVOIR UTILISER NMCOMP
    typmod(1) = 'C_PLAN  '
    typmod(2) = '        '
    npgh = 3
!
!     CONTRAINTE 2D : SIXX,SIYY,SIZZ,SQRT(2)*SIXY
    nbcon = 6
!     NBVAR: NOMBRE DE VARIABLES INTERNES (2D) LOI COMPORT
!     NBCOU : NOMBRE DE COUCHES
    read (zk16(icompo-1+2),'(I16)') nbvar
    call jevech('PNBSP_I', 'L', jnbspi)
    nbcou=zi(jnbspi-1+1)
    call tecach('OOO', 'PVARIMR', 'L', iret, nval=7,&
                itab=jtab)
    if (nbcou .le. 0) then
        call utmess('F', 'ELEMENTS_36', sk=zk16(icompo-1+6))
    endif
!
    hic = h/nbcou
    zmin = -h/deux + distn
    if (vecteu) then
        ndimv=npg*nbsp*nbvar
        call jevech('PVARIMP', 'L', ivarix)
        call dcopy(ndimv, zr(ivarix), 1, zr(ivarip), 1)
    endif
!   coefficients pour calcul de sixz et siyz
    zmax = distn + h/2.d0
    quotient = 1.d0*zmax**3-3*zmax**2*zmin + 3*zmax*zmin**2-1.d0*zmin**3
    a = -6.d0/quotient
    b = 6.d0*(zmin+zmax)/quotient
    c = -6.d0*zmax*zmin/quotient
!
!===============================================================
!
!     -- BOUCLE SUR LES POINTS DE GAUSS DE LA SURFACE:
!     -------------------------------------------------
!     ----- MATRICES ELASTIQUES POUR CALCULER L'EFFORT TRANCHANT--------
       call dxmate(fami, dfel, dmel, dmfel, dcel,&
                   dciel, dmcel, dfcel, nnoel, pgl,&
                   multicel, coupmfel, t2iuel, t2uiel, t1veel)
!
!     -------- CALCUL DE LA MATRICE DE HOOKE EN MEMBRANE ---------------
!    if (multicel .eq. 0) then
!        do 10 k = 1, 9
!            hel(k,1) = dmel(k,1)/h
! 10     continue
!    endif
   do  ino = 1, nnoel
       depfel(1+3*(ino-1)) = uf(1,ino)+duf(1,ino)
       depfel(2+3*(ino-1)) = uf(2,ino)+duf(2,ino)
       depfel(3+3*(ino-1)) = uf(3,ino)+duf(3,ino)
   end do
    do  ipg = 1, npg
        call r8inir(3, 0.d0, n, 1)
        call r8inir(3, 0.d0, m, 1)
        call r8inir(9, 0.d0, df, 1)
        call r8inir(9, 0.d0, dm, 1)
        call r8inir(9, 0.d0, dmf, 1)
        call r8inir(2, 0.d0, dvt, 1)
        call r8inir(2, 0.d0, vt, 1)
        qsi = zr(icoopg-1+ndim*(ipg-1)+1)
        eta = zr(icoopg-1+ndim*(ipg-1)+2)


        if (dkq) then
            call jquad4(xyzl, qsi, eta, jacob)
            poids = zr(ipoids+ipg-1)*jacob(1)
            call dxqbm(qsi, eta, jacob(2), bm)
            call dkqbf(qsi, eta, jacob(2), cara, bf)
!           ------- CALCUL DU PRODUIT HF.T2 -------------------------
                call dsxhft(dfel, jacob(2), hft2el)
!           ------ VT = HFT2.TKT.DEPF -------------------------------
                call dkqtxy(qsi, eta, hft2el, depfel, cara(13),&
                            cara(9), vt)
        else
            poids = zr(ipoids+ipg-1)*cara(7)
            call dxtbm(cara(9), bm)
            call dktbf(qsi, eta, cara, bf)
!   CALCUL DU PRODUIT HF.T2 ----
            call dsxhft(dfel, cara(9), hft2el)
!   VT = HFT2.TKT.DEPF
            call dkttxy(cara(16), cara(13), hft2el, depfel, vt)
        endif
!       -- CALCUL DE EPS, DEPS, KHI, DKHI :
!       -----------------------------------
        call pmrvec('ZERO', 3, 2*nnoel, bm, um,&
                    eps)
        call pmrvec('ZERO', 3, 2*nnoel, bm, dum,&
                    deps)
        call pmrvec('ZERO', 3, 3*nnoel, bf, uf,&
                    khi)
        call pmrvec('ZERO', 3, 3*nnoel, bf, duf,&
                    dkhi)
!
!     -- EULER_ALMANSI - TERMES QUADRATIQUES
        if (leul) then
            call r8inir(6, 0.d0, bmq, 1)
            do  i = 1, 2
                do  k = 1, nnoel
                    do  j = 1, 2
                        bmq(i,j) = bmq(i,j) + bm(i,2*(k-1)+i)*dum(j,k)
                     end do
                    bmq(i,3) = bmq(i,3) + bm(i,2*(k-1)+i)*duf(1,k)
                end do
            end do
!
            do k = 1, 3
                do  i = 1, 2
                    deps(i) = deps(i) - 0.5d0*bmq(i,k)*bmq(i,k)
                end do
                deps(3) = deps(3) - bmq(1,k)*bmq(2,k)
            end do
        endif
!
!       -- CALCUL DE L'ECOULEMENT PLASTIQUE SUR CHAQUE COUCHE:
!          PAR INTEGRATION EN TROIS POINTS
!       ------------------------------------------------------
        do  icou = 1, nbcou
            do  igauh = 1, npgh
                ksp=(icou-1)*npgh+igauh
                isp=(icou-1)*npgh+igauh
                ivpg = ((ipg-1)*nbsp + isp-1)*nbvar
                icpg = ((ipg-1)*nbsp + isp-1)*nbcon
!
!       -- COTE DES POINTS D'INTEGRATION
!       --------------------------------
                if (igauh .eq. 1) then
                    zic = zmin + (icou-1)*hic
                    coef = 1.d0/3.d0
                else if (igauh.eq.2) then
                    zic = zmin + hic/deux + (icou-1)*hic
                    coef = 4.d0/3.d0
                else
                    zic = zmin + hic + (icou-1)*hic
                    coef = 1.d0/3.d0
                endif
!
!         -- CALCUL DE EPS2D ET DEPS2D :
!         --------------------------
                eps2d(1) = eps(1) + zic*khi(1)
                eps2d(2) = eps(2) + zic*khi(2)
                eps2d(3) = 0.0d0
                eps2d(4) = (eps(3)+zic*khi(3))/rac2
                eps2d(5) = 0.d0
                eps2d(6) = 0.d0
                deps2d(1) = deps(1) + zic*dkhi(1)
                deps2d(2) = deps(2) + zic*dkhi(2)
                deps2d(3) = 0.0d0
                deps2d(4) = (deps(3)+zic*dkhi(3))/rac2
                deps2d(5) = 0.d0
                deps2d(6) = 0.d0
!
!
!         -- APPEL A NMCOMP POUR RESOUDRE LE PB SUR LA COUCHE :
!         -----------------------------------------------------
                do  j = 1, 4
                    sigm(j)=zr(icontm+icpg-1+j)
               end do
                sigm(4)=sigm(4)*rac2
! --- ANGLE DU MOT_CLEF MASSIF (AFFE_CARA_ELEM)
! --- INITIALISE A R8VIDE (ON NE S'EN SERT PAS)
                call r8inir(3, r8vide(), angmas, 1)
                do pcontr =1,5
                    zr(icontp+icpg+pcontr)=0.0
                enddo
                call nmcomp('RIGI', ipg, ksp, 2, typmod,&
                            zi(imate), zk16(icompo), zr(icarcr), instm, instp,&
                            4, eps2d, deps2d, 4, sigm,&
                            zr(ivarim+ivpg), opt, angmas, 1, [0.d0],&
                            zr(icontp+ icpg), zr(ivarip+ivpg), 36, dsidep, 1,&
                            wk, cod)
!
!            DIVISION DE LA CONTRAINTE DE CISAILLEMENT PAR SQRT(2)
!            POUR STOCKER LA VALEUR REELLE
!
                zr(icontp+icpg+3)=zr(icontp+icpg+3)/rac2
!           ---- CIST = D1I.VT  -----
!                if (multicel .eq. 0) then
!                  -- MONOCOUCHE
!                  -- COTE DES POINTS D'INTEGRATION
!                  --------------------------------
                     d1iel(1,1) = a*zic*zic + b*zic + c
                     d1iel(2,2) = d1iel(1,1)
                     d1iel(1,2) = 0.d0
                     d1iel(2,1) = 0.d0
                     zr(icontp+icpg+4) = d1iel(1,1)*vt(1) + d1iel(1,2)*vt(2)
                     zr(icontp+icpg+5) = d1iel(2,1)*vt(1) + d1iel(2,2)*vt(2)
!                else
!                  -- EN MULTICOUCHES
!                  -- ON CALCULE TOUT D'UN COUP
!                      iniv = igauh - 2
!                      lmulti = .true.
!                      call dxdmul(lmulti, icou, iniv, t1veel, t2uiel,&
!                                     hel, d1iel, d2iel, zic, hic)
!                      if (dkt) then
!!                           ------- CALCUL DU PRODUIT HL.T2 ---------------------------
!                            call dsxhlt(dfel, cara(9), hlt2el)
!!                           ------ LAMBDA = HLT2.TKT.DEPF -----------------------------
!                            call dktlxy(cara(16), cara(13), hlt2el, depfel, lambda)
!                      elseif (dkq) then
!!                          ------- CALCUL DU PRODUIT HL.T2 -----------------------
!                                     call dsxhlt(dfel, jacob(2), hlt2el)
!!                          ------ LAMBDA = HLT2.TKT.DEPF -------------------------
!                                     call dkqlxy(qsi, eta, hlt2el, depfel, cara(13),&
!                                                 cara(9), lambda)
!                      endif
!                      cist(1) = d1iel(1,1)*vt(1) + d1iel(1,2)*vt(2)
!                      cist(2) = d1iel(2,1)*vt(1) + d1iel(2,2)*vt(2)
!                      do  j = 1, 4
!                          cist(1) = cist(1) + d2iel(1,j)*lambda(j)
!                          cist(2) = cist(2) + d2iel(2,j)*lambda(j)
!                      enddo
!                     zr(icontp+icpg+4) = cist(1)
!                     zr(icontp+icpg+5) = cist(2)
!                endif

!
!           COD=1 : ECHEC INTEGRATION LOI DE COMPORTEMENT
!           COD=3 : C_PLAN DEBORST SIGZZ NON NUL
                if (cod .ne. 0) then
                    if (codret .ne. 1) then
                        codret=cod
                    endif
                endif
!
!         -- CALCUL DES EFFORTS RESULTANTS DANS L'EPAISSEUR (N ET M) :
!         ------------------------------------------------------------
                if (vecteu) then
                    coehsd = coef*hic/deux
                    n(1) = n(1) + coehsd*zr(icontp+icpg-1+1)
                    n(2) = n(2) + coehsd*zr(icontp+icpg-1+2)
                    n(3) = n(3) + coehsd*zr(icontp+icpg-1+4)
                    m(1) = m(1) + coehsd*zic*zr(icontp+icpg-1+1)
                    m(2) = m(2) + coehsd*zic*zr(icontp+icpg-1+2)
                    m(3) = m(3) + coehsd*zic*zr(icontp+icpg-1+4)
                endif
!
!         -- CALCUL DES MATRICES TANGENTES MATERIELLES (DM,DF,DMF):
!         ---------------------------------------------------------
                if (matric) then
!           -- ON EXTRAIT DE DSIDEP LA SOUS-MATRICE INTERESSANTE D2D:
                    d2d(1) = dsidep(1,1)
                    d2d(2) = dsidep(1,2)
                    d2d(3) = dsidep(1,4)/rac2
                    d2d(4) = dsidep(2,1)
                    d2d(5) = dsidep(2,2)
                    d2d(6) = dsidep(2,4)/rac2
                    d2d(7) = dsidep(4,1)/rac2
                    d2d(8) = dsidep(4,2)/rac2
                    d2d(9) = dsidep(4,4)/deux
                    do  k = 1, 9
                        dm(k) = dm(k) + coef*hic/deux*poids*d2d(k)
                        dmf(k) = dmf(k) + coef*hic/deux*poids*zic*d2d( k)
                        df(k) = df(k) + coef*hic/deux*poids*zic*zic* d2d(k)
                    end do
                endif
          end do
        end do
!
!       -- CALCUL DE DIV(SIGMA) ET RECOPIE DE N ET M DANS 'PCONTPR':
!       ----------------------------------------------------------
!       BTSIG = BTSIG + BFT*M + BMT*N
        if (vecteu) then
            do ino = 1, nnoel
                do k = 1, 3
                    btsig(1,ino) = btsig(1,ino) + bm(k,2* (ino-1)+1)* n(k)*poids
                    btsig(2,ino) = btsig(2,ino) + bm(k,2* (ino-1)+2)* n(k)*poids
                    btsig(3,ino) = btsig(3,ino) + bf(k,3* (ino-1)+1)* m(k)*poids
                    btsig(5,ino) = btsig(5,ino) + bf(k,3* (ino-1)+2)* m(k)*poids
                    btsig(4,ino) = btsig(4,ino) - bf(k,3* (ino-1)+3)* m(k)*poids
                end do
         end do
        endif
!
!
!       -- CALCUL DE LA MATRICE TANGENTE :
!       ----------------------------------
!       KTANG = KTANG + BFT*DF*BF + BMT*DM*BM + BMT*DMF*BF
        if (matric) then
!         -- MEMBRANE :
!         -------------
            call utbtab('CUMU', 3, 2*nnoel, dm, bm,&
                        work, memb)
!
!         -- FLEXION :
!         ------------
            call utbtab('CUMU', 3, 3*nnoel, df, bf,&
                        work, flex)
!
!         -- COUPLAGE:
!         ------------
            call utctab('CUMU', 3, 3*nnoel, 2*nnoel, dmf,&
                        bf, bm, work, mefl)
        endif
!
!       -- FIN BOUCLE SUR LES POINTS DE GAUSS
 end do
!
!     -- ACCUMULATION DES SOUS MATRICES DANS KTAN :
!     -----------------------------------------------
    if (matric) then
        if (dkt) then
            call dxtloc(flex, memb, mefl, ctor, ktan)
        else
            call dxqloc(flex, memb, mefl, ctor, ktan)
        endif
    endif
end subroutine
