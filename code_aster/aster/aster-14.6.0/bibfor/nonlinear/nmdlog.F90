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
!
subroutine nmdlog(fami, option, typmod, ndim, nno,&
                  npg, iw, ivf, vff, idff,&
                  geomi, dff, compor, mult_comp, mate, lgpg,&
                  carcri, angmas, instm, instp, matsym,&
                  deplm, depld, sigm, vim, sigp,&
                  vip, fint, matuu, codret)
!
implicit none
!
#include "asterf_types.h"
#include "asterfort/assert.h"
#include "asterfort/codere.h"
#include "asterfort/dfdmip.h"
#include "asterfort/lcegeo.h"
#include "asterfort/nmcomp.h"
#include "asterfort/nmepsi.h"
#include "asterfort/nmgrtg.h"
#include "asterfort/poslog.h"
#include "asterfort/prelog.h"
#include "asterfort/r8inir.h"
#include "asterfort/utmess.h"
#include "blas/daxpy.h"
#include "blas/dcopy.h"
#include "asterfort/Behaviour_type.h"
!
! ----------------------------------------------------------------------
!     BUT:  CALCUL  DES OPTIONS RIGI_MECA_*, RAPH_MECA ET FULL_MECA_*
!           EN GRANDES DEFORMATIONS 2D (D_PLAN ET AXI) ET 3D LOG
!           SUIVANT ARTICLE MIEHE APEL LAMBRECHT CMAME 2002
! ----------------------------------------------------------------------
! IN  FAMI    : FAMILLE DE POINTS DE GAUSS
! IN  OPTION  : OPTION DE CALCUL
! IN  TYPMOD  : TYPE DE MODELISATION
! IN  NDIM    : DIMENSION DE L'ESPACE
! IN  NNO     : NOMBRE DE NOEUDS DE L'ELEMENT
! IN  NPG     : NOMBRE DE POINTS DE GAUSS
! IN  IW      : PTR. POIDS DES POINTS DE GAUSS
! IN  VFF     : VALEUR  DES FONCTIONS DE FORME
! IN  IDFF    : PTR. DERIVEE DES FONCTIONS DE FORME ELEMENT DE REF.
! IN  GEOMI   : COORDONNEES DES NOEUDS (CONFIGURATION INITIALE)
! MEM DFF     : ESPACE MEMOIRE POUR LA DERIVEE DES FONCTIONS DE FORME
!               DIM :(NNO,3) EN 3D, (NNO,4) EN AXI, (NNO,2) EN D_PLAN
! IN  COMPOR  : COMPORTEMENT
! IN  MATE    : MATERIAU CODE
! IN  LGPG    : DIMENSION DU VECTEUR DES VAR. INTERNES POUR 1 PT GAUSS
! IN  CRIT    : CRITERES DE CONVERGENCE LOCAUX
! IN  ANGMAS  : LES TROIS ANGLES DU MOT_CLEF MASSIF (AFFE_CARA_ELEM)
! IN  INSTM   : VALEUR DE L'INSTANT T-
! IN  INSTP   : VALEUR DE L'INSTANT T+
! IN  MATSYM  : .TRUE. SI MATRICE SYMETRIQUE
! IN  DEPLM   : DEPLACEMENT EN T-
! IN  DEPLD   : INCREMENT DE DEPLACEMENT ENTRE T- ET T+
! IN  SIGM    : CONTRAINTES DE CAUCHY EN T-
! IN  VIM     : VARIABLES INTERNES EN T-
! OUT SIGP    : CONTRAINTES DE CAUCHY (RAPH_MECA ET FULL_MECA_*)
! OUT VIP     : VARIABLES INTERNES    (RAPH_MECA ET FULL_MECA_*)
! OUT FINT    : FORCES INTERIEURES (RAPH_MECA ET FULL_MECA_*)
! OUT MATUU   : MATR. DE RIGIDITE NON SYM. (RIGI_MECA_* ET FULL_MECA_*)
! OUT CODRET  : CODE RETOUR DE L'INTEGRATION DE LA LDC
!
    aster_logical :: grand, axi, resi, rigi, matsym, cplan, lintbo
    parameter (grand = .true._1)
    integer :: g, nddl, cod(27), ivf, jvariext1, jvariext2
    integer :: ndim, nno, npg, mate, lgpg, codret, iw, idff
    character(len=8) :: typmod(*)
    character(len=*) :: fami
    character(len=16) :: option
    character(len=16), intent(in) :: compor(*)
    character(len=16), intent(in) :: mult_comp
    real(kind=8), intent(in) :: carcri(*)
    real(kind=8) :: geomi(*), dff(nno, *), instm, instp
    real(kind=8) :: vff(nno, npg), dtde(6, 6)
    real(kind=8) :: angmas(3), deplm(*), depld(*), sigm(2*ndim, npg), epsml(6)
    real(kind=8) :: vim(lgpg, npg), sigp(2*ndim, npg), vip(lgpg, npg)
    real(kind=8) :: matuu(*), fint(ndim*nno)
    real(kind=8) :: geomm(3*27), geomp(3*27), fm(3, 3), fp(3, 3), deplt(3*27)
    real(kind=8) :: r, poids, elgeom(10, 27), tn(6), tp(6), deps(6)
    real(kind=8) :: gn(3, 3), lamb(3), logl(3), rbid(1)
    real(kind=8) :: def(2*ndim, nno, ndim), pff(2*ndim, nno, nno)
    real(kind=8) :: dsidep(6, 6), pk2(6), pk2m(6)
!
!-----------------------------TEST AVANT CALCUL---------------------
!
!     TEST SUR LE NOMBRE DE NOEUDS SI TEST NON VERIFIE MESSAGE ERREUR
    ASSERT(nno.le.27)
    if (compor(5)(1:7) .eq. 'DEBORST') then
        ASSERT(.false.)
    endif
    elgeom(:,:) = 0.d0
!
! -----------------------------DECLARATION-----------------------------
    nddl = ndim*nno
!
!     AFFECTATION DES VARIABLES LOGIQUES  OPTIONS ET MODELISATION
    axi = typmod(1).eq.'AXIS'
    cplan= typmod(1).eq.'C_PLAN'
    resi = option(1:4).eq.'RAPH' .or. option(1:4).eq.'FULL'
    rigi = option(1:4).eq.'RIGI' .or. option(1:4).eq.'FULL'
!
! - Get coded integers for external state variables
!
    jvariext1 = nint(carcri(IVARIEXT1))
    jvariext2 = nint(carcri(IVARIEXT2))
!
! - Compute intrinsic external state variables
!
    call lcegeo(nno   , npg      , ndim     ,&
                iw    , ivf      , idff     ,&
                typmod, jvariext1, jvariext2,&
                geomi ,&
                deplm , depld)
!
!--------------------------INITIALISATION------------------------
!
    cod(:) = 0
    lintbo = .false.
!
!------------------------------DEPLACEMENT ET GEOMETRIE-------------
!
!    DETERMINATION DES CONFIGURATIONS EN T- (GEOMM) ET T+ (GEOMP)
    call dcopy(nddl, geomi, 1, geomm, 1)
    call daxpy(nddl, 1.d0, deplm, 1, geomm, 1)
    call dcopy(nddl, geomm, 1, geomp, 1)
!     DEPLT : DEPLACEMENT TOTAL ENTRE CONF DE REF ET INSTANT T_N+1
    call dcopy(nddl, deplm, 1, deplt, 1)
    if (resi) then
        call daxpy(nddl, 1.d0, depld, 1, geomp, 1)
        call daxpy(nddl, 1.d0, depld, 1, deplt, 1)
    endif
!
!****************************BOUCLE SUR LES POINTS DE GAUSS************
!
! - CALCUL POUR CHAQUE POINT DE GAUSS
    do g = 1, npg
!
!---     CALCUL DE F_N, F_N+1 PAR RAPPORT A GEOMI GEOM INITIAL
        call dfdmip(ndim, nno, axi, geomi, g,&
                    iw, vff(1, g), idff, r, poids,&
                    dff)
!
        call nmepsi(ndim, nno, axi, grand, vff(1, g),&
                    r, dff, deplm, fm)
        call nmepsi(ndim, nno, axi, grand, vff(1, g),&
                    r, dff, deplt, fp)
!
        call prelog(ndim, lgpg, vim(1, g), gn, lamb,&
                    logl, fm, fp, epsml, deps,&
                    tn, resi, cod(g))
!
        if (cod(g) .ne. 0) goto 999
!
        call r8inir(36, 0.d0, dtde, 1)
        call r8inir(6, 0.d0, tp, 1)
        call nmcomp(fami, g, 1, ndim, typmod,&
                    mate, compor, carcri, instm, instp,&
                    6, epsml, deps, 6, tn,&
                    vim(1, g), option, angmas, 10, elgeom(1, g),&
                    tp, vip(1, g), 36, dtde, 1,&
                    rbid, cod(g), mult_comp)
!
!        TEST SUR LES CODES RETOUR DE LA LOI DE COMPORTEMENT
!
        if (cod(g) .eq. 1) goto 999
        if (cod(g) .eq. 4) lintbo= .true.
!
        call poslog(resi, rigi, tn, tp, fm,&
                    lgpg, vip(1, g), ndim, fp, g,&
                    dtde, sigm(1, g), cplan, fami, mate,&
                    instp, angmas, gn, lamb, logl,&
                    sigp(1, g), dsidep, pk2m, pk2, cod(g))
!
        if (cod(g) .ne. 0) goto 999
!
!     CALCUL DE LA MATRICE DE RIGIDITE ET DE LA FORCE INTERIEURE
!     CONFG LAGRANGIENNE COMME NMGR3D / NMGR2D
        call nmgrtg(ndim, nno, poids, g, vff,&
                    dff, def, pff, option, axi,&
                    r, fm, fp, dsidep, pk2m,&
                    pk2, matsym, matuu, fint)
!
    end do
    if (lintbo) cod(1) = 4
999 continue
! - SYNTHESE DES CODES RETOURS
!
    call codere(cod, npg, codret)
!
end subroutine
