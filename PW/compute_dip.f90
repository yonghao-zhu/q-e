!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
subroutine compute_dip(dip, dipion, z0)
!
! This routine computes the integral 1/Omega \int \rho(r) r d^3r 
! and gives as output the projection of the dipole in the direction of
! the electric field. (This routine is called only if tefield is true)
! The direction is the reciprocal lattice vector bg(.,edir)
!
use pwcom
#ifdef __PARA
   use para
#endif
implicit none
real(kind=dp) :: dip, dipion
real(kind=dp), allocatable :: rrho (:), aux(:), rws(:,:)
real(kind=dp) :: dipol_ion(3), dipol(3)

integer:: ipol, i, j, k, i1, j1, k11, na, is, ir
integer:: nrws, nrwsx
real(kind=dp) :: deltax, deltay, deltaz, rijk(3), bmod, proj, x0(3), z0
real(kind=dp) :: weight, wsweight
!
!  calculate ionic dipole
!
x0=0.d0
x0(3)=-z0
dipol_ion=0.d0
do na=1,nat
   do ipol=1,3
      dipol_ion(ipol)=dipol_ion(ipol)+zv(ityp(na))*(tau(ipol,na)+x0(ipol))*alat
   enddo
enddo
!
!  collect the charge density: sum over spin and collect in parallel case
!
allocate (rrho(nrx1*nrx2*nrx3))
#ifdef __PARA
allocate(aux(nrx1*nrx2*nrx3))
rrho=0.d0
do is=1,nspin
   call gather (rho(1,is), aux)
   rrho=rrho+aux
enddo 
deallocate(aux)
if (me.eq.1) then
#else
rrho=0.d0
do is=1,nspin
   rrho=rrho+rho(:,is)
enddo
#endif

   nrwsx=125
   allocate(rws(0:3,nrwsx))
   call wsinit(rws,nrwsx,nrws,at)

   deltax=1.d0/real(nr1,dp)
   deltay=1.d0/real(nr2,dp)
   deltaz=1.d0/real(nr3,dp)
   dipol=0.d0
   do i1 = -nr1/2, nr1/2
      i=i1+1
      if (i.lt.1) i=i+nr1
      do j1 =  -nr2/2,nr2/2
         j=j1+1
         if (j.lt.1) j=j+nr2
         do k11 = -nr3/2, nr3/2
            k=k11+1
            if (k.lt.1) k=k+nr3
            ir=i + (j-1)*nrx1 + (k-1)*nrx1*nrx2
            do ipol=1,3
               rijk(ipol) = real(i1,dp)*at(ipol,1)*deltax + &
                            real(j1,dp)*at(ipol,2)*deltay + &
                            real(k11,dp)*at(ipol,3)*deltaz
            enddo
            weight=wsweight(rijk,rws,nrws)
            do ipol=1,3
               dipol(ipol)=dipol(ipol)+weight*(rijk(ipol)+x0(ipol))*rrho(ir)
            enddo
         enddo
      enddo
   enddo

   dipol=dipol*alat*omega/nr1/nr2/nr3
   write(6,'(5x,"electron", 3f15.5)') dipol(1), dipol(2), dipol(3)
   write(6,'(5x,"ion     ", 3f15.5)') dipol_ion(1), dipol_ion(2), dipol_ion(3)
   write(6,'(5x,"total   ", 3f15.5)') dipol_ion(1)-dipol(1), &
                                      dipol_ion(2)-dipol(2), &
                                      dipol_ion(3)-dipol(3)

   bmod=sqrt(bg(1,edir)**2+bg(2,edir)**2+bg(3,edir)**2)
   proj=0.d0
   do ipol=1,3
      proj=proj+(dipol_ion(ipol)-dipol(ipol))*bg(ipol,edir)
   enddo
   proj=proj/bmod
   dip= fpi*proj/omega

   proj=0.d0
   do ipol=1,3
      proj=proj+dipol_ion(ipol)*bg(ipol,edir)
   enddo
   proj=proj/bmod
   dipion= fpi*proj/omega
   deallocate(rws)

#ifdef __PARA
endif
#endif

   deallocate (rrho)

return
end
