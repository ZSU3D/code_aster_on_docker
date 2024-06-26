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

subroutine fbbbh8(x, b)
!        ELEMENT SHB8-PS A.COMBESCURE, S.BAGUET INSA LYON 2003         !
!-----------------------------------------------------------------------
    implicit none
!
! Flanagan-Belytschko B Bar matrix for Hexa 8-node
! Evaluation of [B] bar matrix components in Flanagan-Belytschko form
!
!
! Evaluation of [B] bar matrix components in Flanagan-Belytschko form
! in corotational frame.
!
!
! IN  x        element nodal coordinates in corotional frame
! OUT b        [B] bar matrix
!
    real(kind=8), intent(in) :: x(24)
    real(kind=8), intent(out) :: b(3, 8)
!
    integer :: i, j
    real(kind=8) :: uns12
    real(kind=8) :: vol, unsvol
!
! ......................................................................
!
    uns12=1.0d0/12.0d0
!
!
!   Evaluate [B] bar matrix components
!
    b(1,1)= x(5)*(x(18)-x(9)+x(15)-x(12))+x(8)*(x(6)-x(12))+&
     & x(11)*(x(9)-x(24)+x(6)-x(15))+x(14)*(x(24)-x(18)+x(12)-x(6))+&
     & x(17)*(x(15)-x(6))+x(23)*(x(12)-x(15))
!
    b(1,2)= x(8)*(x(21)-x(12)+x(18)-x(3))+x(11)*(x(9)-x(3))+&
     & x(2)*(x(12)-x(15)+x(9)-x(18))+x(17)*(x(15)-x(21)+x(3)-x(9))+&
     & x(20)*(x(18)-x(9))+x(14)*(x(3)-x(18))
!
    b(1,3)= x(11)*(x(24)-x(3)+x(21)-x(6))+x(2)*(x(12)-x(6))+&
     & x(5)*(x(3)-x(18)+x(12)-x(21))+x(20)*(x(18)-x(24)+x(6)-x(12))+&
     & x(23)*(x(21)-x(12))+x(17)*(x(6)-x(21))
!
    b(1,4)= x(2)*(x(15)-x(6)+x(24)-x(9))+x(5)*(x(3)-x(9))+&
     & x(8)*(x(6)-x(21)+x(3)-x(24))+x(23)*(x(21)-x(15)+x(9)-x(3))+&
     & x(14)*(x(24)-x(3))+x(20)*(x(9)-x(24))
!
    b(1,5)= x(23)*(x(12)-x(21)+x(3)-x(18))+x(20)*(x(24)-x(18))+&
     & x(17)*(x(21)-x(6)+x(24)-x(3))+x(2)*(x(6)-x(12)+x(18)-x(24))+&
     & x(11)*(x(3)-x(24))+x(5)*(x(18)-x(3))
!
    b(1,6)= x(14)*(x(3)-x(24)+x(6)-x(21))+x(23)*(x(15)-x(21))+&
     & x(20)*(x(24)-x(9)+x(15)-x(6))+x(5)*(x(9)-x(3)+x(21)-x(15))+&
     & x(2)*(x(6)-x(15))+x(8)*(x(21)-x(6))
!
    b(1,7)= x(17)*(x(6)-x(15)+x(9)-x(24))+x(14)*(x(18)-x(24))+&
     & x(23)*(x(15)-x(12)+x(18)-x(9))+x(8)*(x(12)-x(6)+x(24)-x(18))+&
     & x(5)*(x(9)-x(18))+x(11)*(x(24)-x(9))
!
    b(1,8)= x(20)*(x(9)-x(18)+x(12)-x(15))+x(17)*(x(21)-x(15))+&
     & x(14)*(x(18)-x(3)+x(21)-x(12))+x(11)*(x(3)-x(9)+x(15)-x(21))+&
     & x(8)*(x(12)-x(21))+x(2)*(x(15)-x(12))
!
!
    b(2,1)= x(6)*(x(16)-x(7)+x(13)-x(10))+x(9)*(x(4)-x(10))+&
     & x(12)*(x(7)-x(22)+x(4)-x(13))+x(15)*(x(22)-x(16)+x(10)-x(4))+&
     & x(18)*(x(13)-x(4))+x(24)*(x(10)-x(13))
!
    b(2,2)= x(9)*(x(19)-x(10)+x(16)-x(1))+x(12)*(x(7)-x(1))+&
     & x(3)*(x(10)-x(13)+x(7)-x(16))+x(18)*(x(13)-x(19)+x(1)-x(7))+&
     & x(21)*(x(16)-x(7))+x(15)*(x(1)-x(16))
!
    b(2,3)= x(12)*(x(22)-x(1)+x(19)-x(4))+x(3)*(x(10)-x(4))+&
     & x(6)*(x(1)-x(16)+x(10)-x(19))+x(21)*(x(16)-x(22)+x(4)-x(10))+&
     & x(24)*(x(19)-x(10))+x(18)*(x(4)-x(19))
!
    b(2,4)= x(3)*(x(13)-x(4)+x(22)-x(7))+x(6)*(x(1)-x(7))+&
     & x(9)*(x(4)-x(19)+x(1)-x(22))+x(24)*(x(19)-x(13)+x(7)-x(1))+&
     & x(15)*(x(22)-x(1))+x(21)*(x(7)-x(22))
!
    b(2,5)= x(24)*(x(10)-x(19)+x(1)-x(16))+x(21)*(x(22)-x(16))+&
     & x(18)*(x(19)-x(4)+x(22)-x(1))+x(3)*(x(4)-x(10)+x(16)-x(22))+&
     & x(12)*(x(1)-x(22))+x(6)*(x(16)-x(1))
!
    b(2,6)= x(15)*(x(1)-x(22)+x(4)-x(19))+x(24)*(x(13)-x(19))+&
     & x(21)*(x(22)-x(7)+x(13)-x(4))+x(6)*(x(7)-x(1)+x(19)-x(13))+&
     & x(3)*(x(4)-x(13))+x(9)*(x(19)-x(4))
!
    b(2,7)= x(18)*(x(4)-x(13)+x(7)-x(22))+x(15)*(x(16)-x(22))+&
     & x(24)*(x(13)-x(10)+x(16)-x(7))+x(9)*(x(10)-x(4)+x(22)-x(16))+&
     & x(6)*(x(7)-x(16))+x(12)*(x(22)-x(7))
!
    b(2,8)= x(21)*(x(7)-x(16)+x(10)-x(13))+x(18)*(x(19)-x(13))+&
     & x(15)*(x(16)-x(1)+x(19)-x(10))+x(12)*(x(1)-x(7)+x(13)-x(19))+&
     & x(9)*(x(10)-x(19))+x(3)*(x(13)-x(10))
!
!
    b(3,1)= x(4)*(x(17)-x(8)+x(14)-x(11))+x(7)*(x(5)-x(11))+&
     & x(10)*(x(8)-x(23)+x(5)-x(14))+x(13)*(x(23)-x(17)+x(11)-x(5))+&
     & x(16)*(x(14)-x(5))+x(22)*(x(11)-x(14))
!
    b(3,2)= x(7)*(x(20)-x(11)+x(17)-x(2))+x(10)*(x(8)-x(2))+&
     & x(1)*(x(11)-x(14)+x(8)-x(17))+x(16)*(x(14)-x(20)+x(2)-x(8))+&
     & x(19)*(x(17)-x(8))+x(13)*(x(2)-x(17))
!
    b(3,3)= x(10)*(x(23)-x(2)+x(20)-x(5))+x(1)*(x(11)-x(5))+&
     & x(4)*(x(2)-x(17)+x(11)-x(20))+x(19)*(x(17)-x(23)+x(5)-x(11))+&
     & x(22)*(x(20)-x(11))+x(16)*(x(5)-x(20))
!
    b(3,4)= x(1)*(x(14)-x(5)+x(23)-x(8))+x(4)*(x(2)-x(8))+&
     & x(7)*(x(5)-x(20)+x(2)-x(23))+x(22)*(x(20)-x(14)+x(8)-x(2))+&
     & x(13)*(x(23)-x(2))+x(19)*(x(8)-x(23))
!
    b(3,5)= x(22)*(x(11)-x(20)+x(2)-x(17))+x(19)*(x(23)-x(17))+&
     & x(16)*(x(20)-x(5)+x(23)-x(2))+x(1)*(x(5)-x(11)+x(17)-x(23))+&
     & x(10)*(x(2)-x(23))+x(4)*(x(17)-x(2))
!
    b(3,6)= x(13)*(x(2)-x(23)+x(5)-x(20))+x(22)*(x(14)-x(20))+&
     & x(19)*(x(23)-x(8)+x(14)-x(5))+x(4)*(x(8)-x(2)+x(20)-x(14))+&
     & x(1)*(x(5)-x(14))+x(7)*(x(20)-x(5))
!
    b(3,7)= x(16)*(x(5)-x(14)+x(8)-x(23))+x(13)*(x(17)-x(23))+&
     & x(22)*(x(14)-x(11)+x(17)-x(8))+x(7)*(x(11)-x(5)+x(23)-x(17))+&
     & x(4)*(x(8)-x(17))+x(10)*(x(23)-x(8))
!
    b(3,8)= x(19)*(x(8)-x(17)+x(11)-x(14))+x(16)*(x(20)-x(14))+&
     & x(13)*(x(17)-x(2)+x(20)-x(11))+x(10)*(x(2)-x(8)+x(14)-x(20))+&
     & x(7)*(x(11)-x(20))+x(1)*(x(14)-x(11))
!
!
!   Evaluate element volume
!
    vol= uns12*(b(1,1)*x(1)+b(1,2)*x(4)+b(1,3)*x(7)+b(1,4)*x(10)+&
     &  b(1,5)*x(13)+b(1,6)*x(16)+b(1,7)*x(19)+b(1,8)*x(22))
!
    unsvol = 1.0d0 / vol
!
!   [B] bar matrix assembly
!
    do 10 j = 1, 3
        do 20 i = 1, 8
            b(j,i)= uns12 * b(j,i) * unsvol
20      continue
10  continue
!
end subroutine
