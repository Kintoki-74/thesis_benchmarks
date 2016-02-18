!======================================================================
subroutine rpn2(ixy,maxm,meqn,mwaves,maux,mbc,mx,&
        ql,qr,auxl,auxr,fwave,s,amdq,apdq)
!======================================================================
!
! Solves normal Riemann problems for the 2D SHALLOW WATER equations
!     with topography:
!     #        h_t + (hu)_x + (hv)_y = 0                           #
!     #        (hu)_t + (hu^2 + 0.5gh^2)_x + (huv)_y = -ghb_x      #
!     #        (hv)_t + (huv)_x + (hv^2 + 0.5gh^2)_y = -ghb_y      #

! On input, ql contains the state vector at the left edge of each cell
!     qr contains the state vector at the right edge of each cell
!
! This data is along a slice in the x-direction if ixy=1
!     or the y-direction if ixy=2.

    !  Note that the i'th Riemann problem has left state qr(:,i-1)
!     and right state ql(:,i)
    !  From the basic clawpack routines, this routine is called with
    !     ql = qr
    !
    !
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !                                                                           !
    !      # This Riemann solver is for the shallow water equations.            !
    !                                                                           !
    !       It allows the user to easily select a Riemann solver in             !
    !       riemannsolvers_geo.f. this routine initializes all the variables    !
    !       for the shallow water equations, accounting for wet dry boundary    !
    !       dry cells, wave speeds etc.                                         !
    !                                                                           !
    !           David George, Vancouver WA, Feb. 2009                           !
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    use geoclaw_module, only: g => grav, drytol => dry_tolerance
    use geoclaw_module, only: earth_radius, deg2rad
    use amr_module, only: mcapa

    implicit none
    integer, parameter :: DP = kind(1.d0)

    !input
    integer maxm,meqn,maux,mwaves,mbc,mx,ixy

    real(kind=DP) :: fwave(meqn, mwaves, 1-mbc:maxm+mbc)
    real(kind=DP) :: s(1-mbc:maxm+mbc,mwaves)
    real(kind=DP) :: ql(1-mbc:maxm+mbc, meqn)
    real(kind=DP) :: qr(1-mbc:maxm+mbc, meqn)
    real(kind=DP) :: auxl(1-mbc:maxm+mbc,maux)
    real(kind=DP) :: auxr(1-mbc:maxm+mbc,maux)
    real(kind=DP) :: apdq(meqn,1-mbc:maxm+mbc)
    real(kind=DP) :: amdq(meqn,1-mbc:maxm+mbc)

    !local only
    integer m,i,mw,maxiter,mu,nv
    real(kind=DP) :: wall(3)
    real(kind=DP), dimension(3,3) :: fw
    real(kind=DP) :: sw(3)

    real(kind=DP) :: hR,hL,huR,huL,uR,uL,hvR,hvL,vR,vL,phiR,phiL
    real(kind=DP) :: bR,bL,sL,sR,sRoe1,sRoe2,sE1,sE2,uhat,chat
    real(kind=DP) :: s1m,s2m
    real(kind=DP) :: hstar,hstartest,hstarHLL,sLtest,sRtest
    real(kind=DP) :: tw,dxdc
    real(kind=DP) :: sqghl, sqghr

    real(kind=DP) :: tmp

    logical :: rare1,rare2
    ! Status variable for negative input
    logical :: negative_input = .false.

    !-----------------------Initializing-----------------------------------
    !set normal direction
    if (ixy.eq.1) then
        mu=2
        nv=3
    else
        mu=3
        nv=2
    endif

    !Initialize Riemann problem for grid interface
    s = 0.d0
    fwave = 0.d0
    !      do i=2-mbc,mx+mbc
    !         do mw=1,mwaves
    !             s(i,mw)=0.d0
    !             fwave(1,mw,i)=0.d0
    !             fwave(2,mw,i)=0.d0
    !             fwave(3,mw,i)=0.d0
    !         enddo
    !      enddo
    !zero (small) negative values if they exist
    do i=2-mbc,mx+mbc
    !         if (qr(i-1,1).lt.0.d0) then
    !               qr(i-1,1)=0.d0
    !               qr(i-1,2)=0.d0
    !               qr(i-1,3)=0.d0
    !               negative_input = .true.
    !         endif
        if (ql(i,1).lt.0.d0) then
            ql(i,1)=0.d0
            ql(i,2)=0.d0
            ql(i,3)=0.d0
            negative_input = .true.
        endif
    enddo

    !    !inform of a bad riemann problem from the start
    !    if((qr(i-1,1).lt.0.d0).or.(ql(i,1) .lt. 0.d0)) then
    !        write(*,*) 'Negative input: hl,hr,i=',qr(i-1,1),ql(i,1),i
    !    endif
    if (negative_input) then
        write (*,*) 'Negative input for hl,hr!'
    endif
    !----------------------------------------------------------------------
    !loop through Riemann problems at each grid cell

    ! dir$ simd private(hL,hR,huL,huR,hvL,hvR,bL,bR)
    do i=2-mbc,mx+mbc
        !skip problem if in a completely dry area
!        if (qr(i-1,1) <= drytol .and. ql(i,1) <= drytol) then
!            !   go to 30
!            cycle
!        endif

        if (qr(i-1,1) <= drytol .and. ql(i,1) <= drytol) then
            hL = drytol
            hR = drytol
            huL = 0.d0
            huR = 0.d0
            hvL = 0.d0
            hvR = 0.d0
        else
            !Riemann problem variables
            hL = qr(i-1,1) 
            hR = ql(i,1) 
            huL = qr(i-1,mu) 
            huR = ql(i,mu) 
            hvL=qr(i-1,nv) 
            hvR=ql(i,nv)
        endif
        bL = auxr(i-1,1)
        bR = auxl(i,1)

        !call solve_single_layer_rp(drytol, hL, hR, huL, huR, hvL, hvR, bL, bR, fw, sw)
        call solve_single_layer_rp(drytol, hL, hR, huL, huR, hvL, hvR, bL, bR, &
            fw,sw)
!            fwave(:,:,i), s(i,:))

        do mw=1,3!mwaves
            s(i,mw)=sw(mw)
            fwave(1,mw,i)=fw(1,mw)
            fwave(mu,mw,i)=fw(2,mw)
            fwave(nv,mw,i)=fw(3,mw)
        enddo
    enddo
#if 0
    if (ixy.ne.1) then
        do i=2-mbc,mx+mbc
            do mw=1,3
                tmp = fwave(2,mw,i)
                fwave(2,mw,i) = fwave(3,mw,i)
                fwave(3,mw,i) = tmp
            enddo
        enddo
    endif
#endif
    !==========Capacity for mapping from latitude longitude to physical space====
    if (mcapa.gt.0) then
        do i=2-mbc,mx+mbc
            if (ixy.eq.1) then
                dxdc=(earth_radius*deg2rad)
            else
                dxdc=earth_radius*cos(auxl(i,3))*deg2rad
            endif

            do mw=1,mwaves
                s(i,mw)=dxdc*s(i,mw)
                fwave(1,mw,i)=dxdc*fwave(1,mw,i)
                fwave(2,mw,i)=dxdc*fwave(2,mw,i)
                fwave(3,mw,i)=dxdc*fwave(3,mw,i)
            enddo
        enddo
    endif
    !===============================================================================


    !============= compute fluctuations=============================================
    amdq(1:3,:) = 0.d0
    apdq(1:3,:) = 0.d0
    do i=2-mbc,mx+mbc
        do  mw=1,mwaves
            if (s(i,mw) < 0.d0) then
                amdq(1:3,i) = amdq(1:3,i) + fwave(1:3,mw,i)
            else if (s(i,mw) > 0.d0) then
                apdq(1:3,i)  = apdq(1:3,i) + fwave(1:3,mw,i)
            else
                amdq(1:3,i) = amdq(1:3,i) + 0.5d0 * fwave(1:3,mw,i)
                apdq(1:3,i) = apdq(1:3,i) + 0.5d0 * fwave(1:3,mw,i)
            endif
        enddo
    enddo

    return
end subroutine
