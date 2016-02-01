module test_module
    integer, private, parameter :: DP = kind(1.d0)
    integer, save :: num_calls_rpn2 = 0

    real(kind=DP) :: rpn2_time_start = 0.d0, rpn2_time_end = 0.d0
    real(kind=DP) :: total_time = 0.d0
contains
    subroutine test_stats()
        write(*,*) "Total number of rpn2 calls:", num_calls_rpn2
        write(*,*) "Total time spent in rpn2():", total_time
    end subroutine

    subroutine start_timer()
        num_calls_rpn2 = num_calls_rpn2 + 1
        call cpu_time(rpn2_time_start)
    end subroutine

    subroutine stop_timer()
        call cpu_time(rpn2_time_end)
        total_time = total_time + rpn2_time_end - rpn2_time_start
    end subroutine
end module test_module
