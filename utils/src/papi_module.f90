module papi_module
    use amr_module, only: max1d
    implicit none
#ifndef _PAPI_MODULE_
#define _PAPI_MODULE_
    include 'f90papi.h'
#endif
    private
    ! Floating point types    
    integer, parameter :: SP = kind(1.0)
    integer, parameter :: DP = kind(1.d0)

    ! FLOPS counting related variables
    integer,   parameter            :: numevents = 1
    integer,   dimension(numevents) :: events = (/ PAPI_DP_OPS /)
    integer*8, dimension(numevents) :: values ! To store event results
    integer*8                       :: flpops ! Absolute # of FP ops
    integer*8                       :: maxflpops = 0, minflpops = huge(1_8)
    integer                         :: eventset = PAPI_NULL
    real(kind=DP)                   :: mflops
    real(kind=DP)                   :: avg_mflops = 0.d0
    
    ! Timing
    integer*8                       :: clock_start, clock_end
    real(kind=DP)                   :: total_time = 0.d0, acc_time = 0.d0
    real(kind=DP)                   :: avg_rims = 0.d0 ! Avg. Riemann solves/second

    ! Other
    integer                         :: maxrs = 0, minrs = huge(1_4) ! Min/Max 1d domain length
    logical                         :: riemannstats = .false.
    
    ! PAPI - general
    integer                         :: ret = PAPI_VER_CURRENT
    integer                         :: calls = 0, zerotimes = 0, zeroflops = 0

    save 
    public :: papi_init, papi_start, papi_stop, papi_summary
contains
    subroutine papi_init()
        implicit none

        ! Initialize PAPI library
        call PAPIF_library_init(ret)
        if (ret .lt. 0) then
            print *, "FATAL: An error occured while initializing!", ret
            call exit(1)
        end if

        call PAPIF_create_eventset(eventset, ret)
        ! Add events to be measured
        call PAPIF_add_event(eventset, events, ret)
    end subroutine

    subroutine papi_start()
    !dir$ attributes forceinline :: papi_start
        calls = calls + 1
        call PAPIF_start(eventset, ret)
        ! ======= TIMING =======
        !call PAPIF_get_virt_usec(clock_start)
        call PAPIF_get_real_nsec(clock_start)
        ! ======= TIMING =======
    end subroutine

    subroutine papi_stop(riemann_solves)
    !dir$ attributes forceinline :: papi_stop
        integer, intent(in), optional :: riemann_solves
        ! ======= TIMING =======
        !call PAPIF_get_virt_usec(clock_end)
        call PAPIF_get_real_nsec(clock_end)
        ! ======= TIMING =======
        call PAPIF_stop(eventset, values, ret)
        if (present(riemann_solves) .and. riemann_solves < 1) then
            calls = calls - 1
            return
        endif
        
        ! Count number of zero times (=> insufficient timer resultion)
        if (clock_end - clock_start .eq. 0) zerotimes = zerotimes + 1
        
        ! Total time in microseconds
        total_time = real(clock_end - clock_start, kind=DP)
        flpops = values(1)
        if (flpops .lt. 1) then
            zeroflops = zeroflops + 1
            mflops = 0.d0
        else
            ! Note: if ns timing is used this is actually GFLOPS not MFLOPS
            mflops = real(flpops, kind=DP)/(total_time)
        endif
        
        ! Total time in seconds
        total_time = total_time * 1d-9
        
        ! Riemann solves per second
        if (present(riemann_solves)) then
            riemannstats = .true.
            if (riemann_solves .eq. 0) write(*,*) "Warning: Domain length is 0!"
            avg_rims = (avg_rims*(calls-1) &
                + real(riemann_solves,kind=DP)/total_time) &
                / real(calls, kind=DP)
            maxflpops = max(maxflpops, flpops/riemann_solves)
            minflpops = min(minflpops, flpops/riemann_solves)
            minrs = min(minrs, riemann_solves)
            maxrs = max(maxrs, riemann_solves)
        endif
        ! Total time in seconds
        acc_time = acc_time + total_time

        ! Determine FLOP-related values
        avg_mflops = (avg_mflops*(calls-1)+mflops) / real(calls, kind=DP)
    end subroutine

    subroutine papi_summary(routinename)
        character(len=*), intent(in) :: routinename
        integer, parameter :: of = 42
        !write(*,"(a25,i10)") "Number of FLOPs:", flpops
        !write(*,'(a,i5,f14.8)') "=> TIMER TIME [s]:", N, total_time
        open(of, file='riemannstats.log', status="replace")

        write(of,'(a75)') "=========================================================================================="
        write (of,*) "Statistics for routine: ", routinename
        write(of,'(a75)') "------------------------------------------------------------------------------------------"

        if (zerotimes /= 0 .or. zeroflops /= 0) then
            write(of,*) "ZERO TIMES/ZERO FLOPS ALERT!!!"
            write(of,*) "ZERO TIMES:", zerotimes
            write(of,*) "ZERO FLOPS:", zeroflops
        endif
        write(of,'(a15,2a30)') '# Calls', 'Time(s)', 'GFLOPS'
        write(of,'(i15,f30.4,f30.4)') calls, acc_time, avg_mflops
        write(of,'(a75)') "------------------------------------------------------------------------------------------"

        if (riemannstats) then
            write(of,'(a15,2a30)') 'Avg MRim/s', '[min/max] flops/Rim', '[min/max] Rim/Call (=mx)'
            write(of,'(f15.4,2i15,2i15)') avg_rims/1d6, minflpops, maxflpops, minrs, maxrs
        endif
        write(of,'(a75)') "------------------------------------------------------------------------------------------"
        write(of,'(a15,i15)') "max1d:", max1d
        write(of,'(a75)') "=========================================================================================="
        write(of,*)

!        write(*,'(a43,i14)')  "=> # OF CALLS:", calls
!        write(*,'(a43,f14.8)')"=> ACCUM. TIME [s]:", acc_time
!        write(*,'(a43,f14.8)')"=> PAPI [G|M]FLOPS (AVG):", avg_mflops
!        write(*,'(a43,2i8)')  "=> # ZERO TIMES/FP OPS:", zerotimes, zeroflops
!        if (riemannstats) then
!            write(*,*)          "======= STATS for ", routinename
!            write(*,'(a43,f14.3)')"=> RIEMANN SOLVES/SECOND (AVG):", avg_rims
!            write(*,'(a43,2i8)')  "=> MIN/MAX FP OPS PER RIEMANN SOLVE (AVG):", &
!                minflpops, maxflpops 
!            write(*,'(a43,2i8)')  "=> MIN/MAX RIEMANN SOLVES PER CALL:", minrs, maxrs
!        endif
        !write(42,'(i5,f14.8)') mflops
    end subroutine
end module
