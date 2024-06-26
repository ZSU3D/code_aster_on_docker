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

subroutine pj4dco(mocle, moa1, moa2, nbma1, lima1,&
                  nbno2, lino2, geom1, geom2, corres,&
                  l_dmax, dmax, dala, listIntercz, nbIntercz)
!

! --------------------------------------------------------------------------------------------------

! but :
!   creer une sd corresp_2_mailla
!   donnant la correspondance entre les noeuds de moa2 et les mailles de
!   moa1 dans le cas ou moa1 est 2.5d (surface en 3d)
! ======================================================================

!  pour les arguments : mocle, moa1, moa2, nbma1, lima1, nbno2, lino2
!  voir le cartouche de pjxxut.f

!  in/jxin   geom1    i   : objet jeveux contenant la geometrie des
!                           noeuds du maillage 1 (ou ' ')
!  in/jxin   geom2    i   : objet jeveux contenant la geometrie des
!                           noeuds du maillage 2 (ou ' ')
!                remarque:  les objets geom1 et geom2 ne sont utiles
!                           que lorsque l'on veut truander la geometrie
!                           des maillages
!  in/jxout  corres  k16 : nom de la sd corresp_2_mailla

! --------------------------------------------------------------------------------------------------

implicit none

    integer :: nbma1, lima1(*), nbno2, lino2(*)
    real(kind=8) :: dmax, dala
    character(len=16) :: corres, charbid
    character(len=*) :: geom1, geom2
    character(len=8) :: moa1, moa2
    character(len=*) :: mocle
    character(len=16), optional :: listIntercz
    integer, optional :: nbIntercz

#include "asterf_types.h"
#include "jeveux.h"
#include "asterc/getres.h"
#include "asterfort/assert.h"
#include "asterfort/detrsd.h"
#include "asterfort/dismoi.h"
#include "asterfort/getvtx.h"
#include "asterfort/infniv.h"
#include "asterfort/inslri.h"
#include "asterfort/jedema.h"
#include "asterfort/jedetr.h"
#include "asterfort/jemarq.h"
#include "asterfort/jenuno.h"
#include "asterfort/jeveuo.h"
#include "asterfort/jexatr.h"
#include "asterfort/jexnum.h"
#include "asterfort/pj2dtr.h"
#include "asterfort/pj3dfb.h"
#include "asterfort/pj4dap.h"
#include "asterfort/pjxxut.h"
#include "asterfort/pjloin.h"
#include "asterfort/utimsd.h"
#include "asterfort/utmess.h"
#include "asterfort/wkvect.h"
#include "asterfort/as_allocate.h"
#include "asterfort/as_deallocate.h"

! --------------------------------------------------------------------------------------------------

    character(len=8) :: m1, m2, nono2
    character(len=14) :: boite
    character(len=16) :: cortr3
    integer :: nbtm, nbtmx
    parameter   (nbtmx=15)
    integer :: nutm(nbtmx)
    character(len=8) :: elrf(nbtmx)

    integer :: ifm, niv, nno1, nno2, nma1, nma2, k
    integer :: ima, ino2, ico, ino
    integer :: iatr3, iacoo1, iacoo2
    integer :: iabtco, jxxk1, iaconu, iacocf, iacotr
    integer :: ialim1, ialin1, ilcnx1, ialin2
    integer :: iaconb, itypm, idecal, itr3, nbtrou

    aster_logical :: dbg, l_dmax, loin, loin2, lraff
    real(kind=8) :: dmin, cobary(3)

    integer :: nbmax
    parameter (nbmax=5)
    integer :: tino2m(nbmax), nbnod, nbnodm
    real(kind=8) :: tdmin2(nbmax)
    real(kind=8), pointer :: bt3dvr(:) => null()
    integer, pointer :: bt3dlc(:) => null()
    integer, pointer :: connex(:) => null()
    integer, pointer :: bt3dnb(:) => null()
    integer, pointer :: bt3ddi(:) => null()
    integer, pointer :: typmail(:) => null()
    integer, pointer :: lino_loin(:) => null()
    integer, pointer :: vinterc(:) => null()

! --------------------------------------------------------------------------------------------------

    call jemarq()
    call infniv(ifm, niv)

    call pjxxut('2D', mocle, moa1, moa2, nbma1,&
                lima1, nbno2, lino2, m1, m2,&
                nbtmx, nbtm, nutm, elrf)

    call dismoi('NB_NO_MAILLA', m1, 'MAILLAGE', repi=nno1)
    call dismoi('NB_NO_MAILLA', m2, 'MAILLAGE', repi=nno2)
    call dismoi('NB_MA_MAILLA', m1, 'MAILLAGE', repi=nma1)
    call dismoi('NB_MA_MAILLA', m2, 'MAILLAGE', repi=nma2)

    call jeveuo('&&PJXXCO.LIMA1', 'L', ialim1)
    call jeveuo('&&PJXXCO.LINO1', 'L', ialin1)
    call jeveuo('&&PJXXCO.LINO2', 'L', ialin2)

!   -- l'objet lino_loin contiendra la liste des noeuds projetes un peu loin
    AS_ALLOCATE(vi=lino_loin, size=nno2)


!     2. ON DECOUPE TOUTES LES MAILLES 2D EN TRIA3
!     ------------------------------------------------
!        (EN CONSERVANT LE LIEN DE PARENTE):
!        ON CREE L'OBJET V='&&PJXXCO.TRIA3' : OJB S V I
!           LONG(V)=1+4*NTR3
!           V(1) : NTR3(=NOMBRE DE TRIA3)
!           V(1+4(I-1)+1) : NUMERO DU 1ER  NOEUD DU IEME TRIA3
!           V(1+4(I-1)+2) : NUMERO DU 2EME NOEUD DU IEME TRIA3
!           V(1+4(I-1)+3) : NUMERO DU 3EME NOEUD DU IEME TRIA3
!           V(1+4(I-1)+4) : NUMERO DE LA MAILLE MERE DU IEME TRIA3
    call jeveuo(m1//'.TYPMAIL', 'L', vi=typmail)
    ico=0
    do ima = 1, nma1
        if (zi(ialim1-1+ima) .eq. 0) cycle
        itypm=typmail(ima)
        if (itypm .eq. nutm(1)) then
            ico=ico+1
        else if (itypm.eq.nutm(2)) then
            ico=ico+1
        else if (itypm.eq.nutm(3)) then
            ico=ico+1
        else if (itypm.eq.nutm(4)) then
            ico=ico+2
        else if (itypm.eq.nutm(5)) then
            ico=ico+2
        else if (itypm.eq.nutm(6)) then
            ico=ico+2
        else
            ASSERT(.false.)
            if (ico .eq. 0) then
                call utmess('F', 'CALCULEL4_55')
            endif
        endif
    enddo
    call wkvect('&&PJXXCO.TRIA3', 'V V I', 1+4*ico, iatr3)
    zi(iatr3-1+1)=ico
    call jeveuo(m1//'.CONNEX', 'L', vi=connex)
    call jeveuo(jexatr(m1//'.CONNEX', 'LONCUM'), 'L', ilcnx1)
    ico=0
    do ima = 1, nma1
        if (zi(ialim1-1+ima) .eq. 0) cycle
        itypm=typmail(ima)
!       CAS DES TRIANGLES :
        if ((itypm.eq.nutm(1)) .or. (itypm.eq.nutm(2)) .or. ( itypm.eq.nutm(3))) then
            ico=ico+1
            zi(iatr3+(ico-1)*4+4)=ima
            zi(iatr3+(ico-1)*4+1)=connex(1+ zi(ilcnx1-1+ima)-2+1)
            zi(iatr3+(ico-1)*4+2)=connex(1+ zi(ilcnx1-1+ima)-2+2)
            zi(iatr3+(ico-1)*4+3)=connex(1+ zi(ilcnx1-1+ima)-2+3)
!       CAS DES QUADRANGLES :
        else if ((itypm.eq.nutm(4)).or.(itypm.eq.nutm(5)) .or.(itypm.eq.nutm(6))) then
            ico=ico+1
            zi(iatr3+(ico-1)*4+4)=ima
            zi(iatr3+(ico-1)*4+1)=connex(1+ zi(ilcnx1-1+ima)-2+1)
            zi(iatr3+(ico-1)*4+2)=connex(1+ zi(ilcnx1-1+ima)-2+2)
            zi(iatr3+(ico-1)*4+3)=connex(1+ zi(ilcnx1-1+ima)-2+3)
            ico=ico+1
            zi(iatr3+(ico-1)*4+4)=ima
            zi(iatr3+(ico-1)*4+1)=connex(1+ zi(ilcnx1-1+ima)-2+1)
            zi(iatr3+(ico-1)*4+2)=connex(1+ zi(ilcnx1-1+ima)-2+3)
            zi(iatr3+(ico-1)*4+3)=connex(1+ zi(ilcnx1-1+ima)-2+4)
        endif
    enddo

!     3. ON MET LES TRIA3 EN BOITES :
!     ---------------------------------------------------
    if (geom1 .eq. ' ') then
        call jeveuo(m1//'.COORDO    .VALE', 'L', iacoo1)
    else
        call jeveuo(geom1, 'L', iacoo1)
    endif
    if (geom2 .eq. ' ') then
        call jeveuo(m2//'.COORDO    .VALE', 'L', iacoo2)
    else
        call jeveuo(geom2, 'L', iacoo2)
    endif

    boite='&&PJ4DCO.BOITE'
    call pj3dfb(boite, '&&PJXXCO.TRIA3', zr(iacoo1), zr(iacoo2))
    call jeveuo(boite//'.BT3DDI', 'L', vi=bt3ddi)
    call jeveuo(boite//'.BT3DVR', 'L', vr=bt3dvr)
    call jeveuo(boite//'.BT3DNB', 'L', vi=bt3dnb)
    call jeveuo(boite//'.BT3DLC', 'L', vi=bt3dlc)
    call jeveuo(boite//'.BT3DCO', 'L', iabtco)

!     DESCRIPTION DE LA SD BOITE_3D :
!     BOITE_3D (K14) ::= RECORD
!      .BT3DDI   : OJB S V I  LONG=3
!      .BT3DVR   : OJB S V R  LONG=9
!      .BT3DNB   : OJB S V I  LONG=NX*NY*NZ
!      .BT3DLC   : OJB S V I  LONG=1+NX*NY*NZ
!      .BT3DCO   : OJB S V I  LONG=*

!      .BT3DDI(1) : NX=NOMBRE DE BOITES DANS LA DIRECTION X
!      .BT3DDI(2) : NY=NOMBRE DE BOITES DANS LA DIRECTION Y
!      .BT3DDI(3) : NZ=NOMBRE DE BOITES DANS LA DIRECTION Z

!      .BT3DVR(1) : XMIN     .BT3DVR(2) : XMAX
!      .BT3DVR(3) : YMIN     .BT3DVR(4) : YMAX
!      .BT3DVR(5) : ZMIN     .BT3DVR(6) : ZMAX
!      .BT3DVR(7) : DX = (XMAX-XMIN)/NBX
!      .BT3DVR(8) : DY = (YMAX-YMIN)/NBY
!      .BT3DVR(9) : DZ = (ZMAX-ZMIN)/NBZ

!      .BT3DNB    : LONGUEURS DES BOITES
!      .BT3DNB(1) : NOMBRE DE TRIA3 CONTENUS DANS LA BOITE(1,1,1)
!      .BT3DNB(2) : NOMBRE DE TRIA3 CONTENUS DANS LA BOITE(2,1,1)
!      .BT3DNB(3) : ...
!      .BT3DNB(NX*NY*NZ) : NOMBRE DE TRIA3 CONTENUS DANS LA
!                          DERNIERE BOITE(NX,NY,NZ)

!      .BT3DLC    : LONGUEURS CUMULEES DE .BT3DCO
!      .BT3DLC(1) : 0
!      .BT3DLC(2) : BT3DLC(1)+NBTR3(BOITE(1,1))
!      .BT3DLC(3) : BT3DLC(2)+NBTR3(BOITE(2,1))
!      .BT3DLC(4) : ...

!      .BT3DCO    : CONTENU DES BOITES
!       SOIT :
!        NBTR3 =NBTR3(BOITE(P,Q,R)=BT3DNB((R-1)*NY*NX+(Q-1)*NX+P)
!        DEBTR3=BT3DLC((R-1)*NY*NX+(Q-1)*NX+P)
!        DO K=1,NBTR3
!          TR3=.BT3DCO(DEBTR3+K)
!        DONE
!        TR3 EST LE NUMERO DU KIEME TRIA3 DE LA BOITE (P,Q,R)


!     4. CONSTRUCTION D'UN CORRESP_2_MAILLA TEMPORAIRE :CORTR3
!        (EN UTILISANT LES TRIA3 DEDUITS DU MAILLAGE M1)
!     ---------------------------------------------------
    cortr3='&&PJ4DCO.CORRESP'
    call wkvect(cortr3//'.PJXX_K1', 'V V K24', 5, jxxk1)
    zk24(jxxk1-1+1)=m1
    zk24(jxxk1-1+2)=m2
    zk24(jxxk1-1+3)='COLLOCATION'
    call wkvect(cortr3//'.PJEF_NB', 'V V I', nno2, iaconb)
    call wkvect(cortr3//'.PJEF_NU', 'V V I', 4*nno2, iaconu)
    call wkvect(cortr3//'.PJEF_CF', 'V V R', 3*nno2, iacocf)
    call wkvect(cortr3//'.PJEF_TR', 'V V I', nno2, iacotr)


!     ON CHERCHE POUR CHAQUE NOEUD INO2 DE M2 LE TRIA3
!     AUQUEL IL APPARTIENT AINSI QUE SES COORDONNEES
!     BARYCENTRIQUES DANS CE TRIA3 :
!     ------------------------------------------------
    idecal= 0
    loin2 = .false.
    nbnod = 0
    nbnodm = 0
    do ino2 = 1, nno2
        if (zi(ialin2-1+ino2) .eq. 0) cycle
        call pj4dap(ino2, zr(iacoo2), zr(iacoo1), zi(iatr3),&
                    cobary, itr3, nbtrou, bt3ddi, bt3dvr,&
                    bt3dnb, bt3dlc, zi( iabtco),&
                    l_dmax, dmax, dala, loin, dmin)
        if (loin) then
!           on regarde si le noeud est deja projete par une autre
!           occurrence de VIS_A_VIS
            if (present(nbIntercz))then
                if (nbIntercz .ne. 0)then
                    ASSERT(present(listIntercz))
                    call jeveuo(listIntercz, 'L', vi=vinterc)
                    do ino = 1,nbIntercz
                        if (ino2 .eq. vinterc(ino))then
                            loin = .false.
!                       
                            l_dmax = .true.
                            nbtrou = 0
!
                            call jenuno(jexnum(m2//'.NOMNOE', ino2), nono2)
                            call utmess('A','CALCULEL5_47', si=vinterc(nbIntercz+1),&
                                        sk=nono2)
                            exit
                        endif
                    enddo
                endif
            endif
        endif
        if (loin)then
            loin2=.true.
            nbnodm = nbnodm + 1
            lino_loin(nbnodm)=ino2
        endif
        call inslri(nbmax, nbnod, tdmin2, tino2m, dmin,&
                    ino2)
        if (l_dmax .and. (nbtrou.eq.0)) then
            zi(iaconb-1+ino2)=3
            zi(iacotr-1+ino2)=0
            cycle
        endif
        if (nbtrou .eq. 0) then
            call jenuno(jexnum(m2//'.NOMNOE', ino2), nono2)
            call utmess('F', 'CALCULEL4_56', sk=nono2)
        endif

        zi(iaconb-1+ino2)=3
        zi(iacotr-1+ino2)=itr3
        do k = 1, 3
            zi(iaconu-1+idecal+k)= zi(iatr3+4*(itr3-1)+k)
            zr(iacocf-1+idecal+k)= cobary(k)
        enddo
        idecal=idecal+zi(iaconb-1+ino2)
    enddo

!   EMISSION D'UN EVENTUEL MESSAGE D'ALARME:
    if (loin2) then
        call pjloin(nbnod,nbnodm,m2,zr(iacoo2),nbmax,tino2m,tdmin2,lino_loin)
    endif


!   5. on transforme cortr3 en corres (retour aux vraies mailles)
!   -------------------------------------------------------------
    lraff=.true.
    charbid = ' '
    call pj2dtr(cortr3, corres, nutm, elrf, zr(iacoo1), zr(iacoo2), lraff, dala,&
               charbid, 0)
    dbg=.false.
    if (dbg) then
        call utimsd(ifm, 2, ASTER_FALSE, ASTER_TRUE, '&&PJ4DCO', 1, ' ')
        call utimsd(ifm, 2, ASTER_FALSE, ASTER_TRUE, corres, 1, ' ')
    endif
    call detrsd('CORRESP_2_MAILLA', cortr3)

    call jedetr(boite//'.BT3DDI')
    call jedetr(boite//'.BT3DVR')
    call jedetr(boite//'.BT3DNB')
    call jedetr(boite//'.BT3DLC')
    call jedetr(boite//'.BT3DCO')

    call jedetr('&&PJXXCO.TRIA3')
    call jedetr('&&PJXXCO.LIMA1')
    call jedetr('&&PJXXCO.LIMA2')
    call jedetr('&&PJXXCO.LINO1')
    call jedetr('&&PJXXCO.LINO2')

    AS_DEALLOCATE(vi=lino_loin)

    call jedema()
end subroutine
