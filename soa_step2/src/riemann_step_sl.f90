subroutine solve_single_layer_rp(drytol, hL, hR, huL, huR, hvL, hvR, bL, bR, fw, sw)
    !dir$ attributes vector :: solve_single_layer_rp
    use geoclaw_module, only: g => grav
    implicit none

    ! Input
    real(kind=8), intent(in) :: drytol

    ! Output
    real(kind=8), intent(in out) :: fw(3, 3), sw(3)

    ! Locals
    integer :: mw
    real(kind=8), intent(inout) :: hL, hR, huL, huR, hvL, hvR, bL, bR
    real(kind=8) :: uL, uR, vL, vR
    real(kind=8) :: phiL, phiR, wall(3)
    real(kind=8) :: hstar, hstartest, s1m, s2m, rare1, rare2, sL, sR, uhat, chat, sRoe1, sRoe2, sE1, sE2

    ! Parameters (should be anyway)
    integer :: maxiter

    ! ========================================
    !  Begin Snipped Code From rpn2_geoclaw.f
    ! ========================================
    !check for wet/dry boundary
     if (hR.gt.drytol) then
        uR=huR/hR
        vR=hvR/hR
        phiR = 0.5d0*g*hR**2 + huR**2/hR
     else
        uR = 0.d0
        vR = 0.d0
        phiR = 0.d0
        hR = 0.d0
        huR = 0.d0
        hvR = 0.d0
     endif

     if (hL.gt.drytol) then
        uL=huL/hL
        vL=hvL/hL
        phiL = 0.5d0*g*hL**2 + huL**2/hL
     else
        uL=0.d0
        vL=0.d0
        phiL = 0.d0
        hL=0.d0
        huL=0.d0
        hvL=0.d0
     endif

     wall(1) = 1.d0
     wall(2) = 1.d0
     wall(3) = 1.d0
#if 1
     !if (hR.le.drytol) then
     if (hR.lt.drytol) then
        !dir$ forceinline
        call riemanntype(hL,hL,uL,-uL,hstar,s1m,s2m,&
            rare1,rare2,1,drytol,g)
        hstartest=max(hL,hstar)
        if (hstartest+bL.lt.bR) then !right state should become ghost values that mirror left for wall problem
!                bR=hstartest+bL
           wall(2)=0.d0
           wall(3)=0.d0
           hR=hL
           huR=-huL
           bR=bL
           phiR=phiL
           uR=-uL
           vR=vL
        elseif (hL+bL.lt.bR) then
           bR=hL+bL
        endif
     !elseif (hL.le.drytol) then ! right surface is lower than left topo
     elseif (hL.lt.drytol) then ! right surface is lower than left topo
        !dir$ forceinline
        call riemanntype(hR,hR,-uR,uR,hstar,s1m,s2m,&
            rare1,rare2,1,drytol,g)
        hstartest=max(hR,hstar)
        if (hstartest+bR.lt.bL) then  !left state should become ghost values that mirror right
!               bL=hstartest+bR
           wall(1)=0.d0
           wall(2)=0.d0
           hL=hR
           huL=-huR
           bL=bR
           phiL=phiR
           uL=-uR
           vL=vR
        elseif (hR+bR.lt.bL) then
           bL=hR+bR
        endif
     endif
#endif
     !determine wave speeds
     sL=uL-sqrt(g*hL) ! 1 wave speed of left state
     sR=uR+sqrt(g*hR) ! 2 wave speed of right state

     if (sqrt(g*hR)+sqrt(g*hL) > drytol) then
         uhat=(sqrt(g*hL)*uL + sqrt(g*hR)*uR)/(sqrt(g*hR)+sqrt(g*hL)) ! Roe average
     else
         uhat = 0.d0
     endif
     chat=sqrt(g*0.5d0*(hR+hL)) ! Roe average
     sRoe1=uhat-chat ! Roe wave speed 1 wave
     sRoe2=uhat+chat ! Roe wave speed 2 wave

     sE1 = min(sL,sRoe1) ! Eindfeldt speed 1 wave
     sE2 = max(sR,sRoe2) ! Eindfeldt speed 2 wave

     !--------------------end initializing...finally----------
     !solve Riemann problem.

     maxiter = 1
#if 1
     ! dir$ forceinline
      call riemann_fwave(3,3,hL,hR,huL,huR,hvL,hvR, &
       bL,bR,uL,uR,vL,vR,phiL,phiR,sE1,sE2,drytol,g,sw,fw)
#endif
!        !eliminate ghost fluxes for wall
    do mw=1,3
        sw(mw)  =sw(mw)*wall(mw)
        fw(1,mw)=fw(1,mw)*wall(mw) 
        fw(2,mw)=fw(2,mw)*wall(mw)
        fw(3,mw)=fw(3,mw)*wall(mw)
    enddo
    
!    do mw=1,mwaves
!        s(i,mw)=sw(mw)
!        fwave(1,mw,i)=fw(1,mw)
!        fwave(mu,mw,i)=fw(2,mw)
!        fwave(nv,mw,i)=fw(3,mw)
!    enddo

end subroutine solve_single_layer_rp
